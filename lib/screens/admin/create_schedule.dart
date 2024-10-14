import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/schedule_model.dart';

class CreateSchedulePage extends StatefulWidget {
  final Schedule? schedule;

  const CreateSchedulePage({Key? key, this.schedule}) : super(key: key);

  @override
  _CreateSchedulePageState createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _collectorController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String? _selectedCity;
  String? _selectedCollector; // Store the selected waste collector
  List<String> _cities = [];
  List<String> _userIdsFromCity = [];
  List<String> _binIdsFromCity = []; // List to store bin IDs
  List<String> _wasteRequestIds = []; // List to store waste collection request IDs
  List<String> _collectors = []; // List to store waste collector names

  final Color darkGreen = Color(0xFF2E7D32);
  final Color green = Color(0xFF4CAF50);
  final Color lightGreen = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      // Pre-fill form fields for editing
      _selectedCity = widget.schedule!.city;
      _collectorController.text = widget.schedule!.wasteCollector;
      _startDate = widget.schedule!.startTime;
      _endDate = widget.schedule!.endTime;
      _startTime = TimeOfDay.fromDateTime(widget.schedule!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.schedule!.endTime);
    } else {
      // Default values for creating a new schedule
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(hours: 1));
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.now();
    }
    _fetchCities();
    _fetchCollectors(); // Fetch waste collectors when initializing
  }

  // Fetch unique cities from 'users' collection
  Future<void> _fetchCities() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final cities = usersSnapshot.docs.map((doc) => doc['city'] as String).toSet().toList();

    setState(() {
      _cities = cities;
    });
  }

  // Fetch waste collectors from the 'users' collection
  Future<void> _fetchCollectors() async {
    QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'wasteCollector')
        .get();

    List<String> collectorNames = [];

    for (var doc in collectorsSnapshot.docs) {
      collectorNames.add(doc['name']); // Add collector name to the list
    }

    setState(() {
      _collectors = collectorNames; // Update state with collector names
    });
  }

  // Fetch users and bin IDs from the selected city with pending waste collection requests where `isScheduled` is false
  Future<void> _fetchUsersFromCity() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('city', isEqualTo: _selectedCity)
        .get();

    List<String> userIds = [];
    List<String> binIds = []; // List to hold bin IDs
    List<String> wasteRequestIds = []; // List to hold waste collection request IDs

    for (var doc in usersSnapshot.docs) {
      String userId = doc['uid'];

      // Check if the user has a pending waste collection request with `isScheduled = false`
      QuerySnapshot requestsSnapshot = await FirebaseFirestore.instance
          .collection('wasteCollectionRequests')
          .where('userId', isEqualTo: userId)
          .where('isCollected', isEqualTo: false) // Check for uncollected requests
          .where('isScheduled', isEqualTo: false) // Check if the request is not scheduled
          .get();

      if (requestsSnapshot.docs.isNotEmpty) {
        userIds.add(userId);
        // Add binId and waste request IDs from the wasteCollectionRequests
        for (var request in requestsSnapshot.docs) {
          binIds.add(request['binId']); // Collect binId
          wasteRequestIds.add(request.id); // Store the request ID to update `isScheduled` later
        }
      }
    }

    setState(() {
      _userIdsFromCity = userIds;
      _binIdsFromCity = binIds; // Store bin IDs
      _wasteRequestIds = wasteRequestIds; // Store request IDs
    });
  }

  // After creating/updating a schedule, set `isScheduled = true` for those requests
  Future<void> _markRequestsAsScheduled() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (String requestId in _wasteRequestIds) {
      DocumentReference requestRef =
          FirebaseFirestore.instance.collection('wasteCollectionRequests').doc(requestId);

      // Update `isScheduled` to true for each request
      batch.update(requestRef, {'isScheduled': true});
    }

    await batch.commit(); // Commit batch update
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Creating a new schedule, so fetch users and bin IDs before submission
      await _fetchUsersFromCity();

      // Check if there are no pending waste collection requests
      if (_userIdsFromCity.isEmpty) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('There are no requests for scheduling in this city.')),
        );
        return; // Prevent form submission
      }

      DateTime startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      DateTime endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Find the user ID for the selected waste collector
      String wasteCollectorId = await _fetchWasteCollectorId(_selectedCollector!); // Get collector ID

      final schedule = Schedule(
        city: _selectedCity!,
        wasteCollector: _selectedCollector!,
        wasteCollectorId: wasteCollectorId, // Use the collector ID
        startTime: startDateTime,
        endTime: endDateTime,
        userIds: _userIdsFromCity, // Keep the existing userIds when updating
        bins: _binIdsFromCity, // Save the collected bin IDs
        isScheduled: true
      );

      final scheduleData = schedule.toMap();

      // Create new schedule
      await FirebaseFirestore.instance.collection('schedules').add(scheduleData);

      // Mark waste collection requests as scheduled
      await _markRequestsAsScheduled();

      Navigator.pop(context);
    }
  }

  // Method to fetch the waste collector ID from the collectors' list
  Future<String> _fetchWasteCollectorId(String collectorName) async {
    QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: collectorName)
        .get();

    if (collectorsSnapshot.docs.isNotEmpty) {
      return collectorsSnapshot.docs.first.id; // Return the ID of the first matching collector
    }

    throw Exception('Waste collector not found');
  }



  // Method for picking the date
  Future<void> _pickDate({required bool isStartDate}) async {
    DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStartTime}) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.schedule == null ? 'Create New Schedule' : 'Edit Schedule',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkGreen,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightGreen.withOpacity(0.2), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.schedule == null ? 'Create New Schedule' : 'Edit Schedule',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildDropdown(
                      label: 'City',
                      value: _selectedCity,
                      items: _cities,
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Waste Collector',
                      value: _selectedCollector,
                      items: _collectors,
                      onChanged: (value) {
                        setState(() {
                          _selectedCollector = value;
                          _collectorController.text = value ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    _buildDateTimeRow('Start Time:', _startDate, _startTime, isStart: true),
                    SizedBox(height: 16),
                    _buildDateTimeRow('End Time:', _endDate, _endTime, isStart: false),
                    SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          widget.schedule == null ? 'Create Schedule' : 'Update Schedule',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a $label' : null,
      dropdownColor: Colors.white,
      style: TextStyle(color: darkGreen),
      icon: Icon(Icons.arrow_drop_down, color: green),
    );
  }

  Widget _buildDateTimeRow(String label, DateTime date, TimeOfDay time, {required bool isStart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStartDate: isStart),
                icon: Icon(Icons.calendar_today, color: green),
                label: Text(DateFormat('yyyy-MM-dd').format(date), style: TextStyle(color: darkGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(isStartTime: isStart),
                icon: Icon(Icons.access_time, color: green),
                label: Text(time.format(context), style: TextStyle(color: darkGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}