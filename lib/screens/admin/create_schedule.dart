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
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _collectorController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String? _selectedCity;
  List<String> _cities = [];
  List<String> _userIdsFromCity = [];
  List<String> _binIdsFromCity = []; // List to store bin IDs
  List<String> _wasteRequestIds = []; // List to store waste collection request IDs

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      // Pre-fill form fields for editing
      _selectedCity = widget.schedule!.city;
      _vehicleController.text = widget.schedule!.vehicleNumber;
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
  }

  // Fetch unique cities from 'users' collection
  Future<void> _fetchCities() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final cities = usersSnapshot.docs.map((doc) => doc['city'] as String).toSet().toList();

    setState(() {
      _cities = cities;
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
          binIds.add(request['binId']);
          wasteRequestIds.add(request.id); // Store the request ID to update `isScheduled` later
        }
      }
    }

    setState(() {
      _userIdsFromCity = userIds;
      _binIdsFromCity = binIds;
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
      await _fetchUsersFromCity(); // Fetch users and bin IDs before submission

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

      final schedule = Schedule(
        id: widget.schedule?.id,
        city: _selectedCity!,
        vehicleNumber: _vehicleController.text,
        wasteCollector: _collectorController.text,
        startTime: startDateTime,
        endTime: endDateTime,
      );

      final scheduleData = schedule.toMap();
      scheduleData['userIds'] = _userIdsFromCity; // Add user IDs to the schedule
      scheduleData['binIds'] = _binIdsFromCity; // Add bin IDs to the schedule

      if (widget.schedule == null) {
        // Create new schedule
        await FirebaseFirestore.instance.collection('schedules').add(scheduleData);
      } else {
        // Update existing schedule
        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(widget.schedule!.id)
            .update(scheduleData);
      }

      // Mark waste collection requests as scheduled
      await _markRequestsAsScheduled();

      Navigator.pop(context);
    }
  }

  // Method for picking the date
  Future<void> _pickDate({required bool isStartDate}) async {
    DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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

  // Method for picking the time
  Future<void> _pickTime({required bool isStartTime}) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
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
        title: Text(widget.schedule == null ? 'Create New Schedule' : 'Edit Schedule'),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
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
                // City Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  value: _selectedCity,
                  items: _cities
                      .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a city' : null,
                ),
                const SizedBox(height: 8),
                
                _textField('Vehicle Number:', _vehicleController),
                const SizedBox(height: 8),
                _textField('Waste Collector:', _collectorController),
                const SizedBox(height: 16),
                
                _dateTimeRow('Start Time:', _startDate, _startTime, () => _pickDate(isStartDate: true), () => _pickTime(isStartTime: true)),
                const SizedBox(height: 8),
                
                _dateTimeRow('End Time:', _endDate, _endTime, () => _pickDate(isStartDate: false), () => _pickTime(isStartTime: false)),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(widget.schedule == null ? Icons.add : Icons.edit),
                      label: Text(widget.schedule == null ? 'Create Schedule' : 'Update Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 51, 126, 201),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          validator: (value) => value!.isEmpty ? 'Enter $label' : null,
        ),
      ],
    );
  }

  Widget _dateTimeRow(String label, DateTime date, TimeOfDay time, VoidCallback onPickDate, VoidCallback onPickTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
            ElevatedButton(
              onPressed: onPickDate,
              child: Text('Select Date'),
            ),
            Text('Time: ${time.format(context)}'),
            ElevatedButton(
              onPressed: onPickTime,
              child: Text('Select Time'),
            ),
          ],
        ),
      ],
    );
  }
}
