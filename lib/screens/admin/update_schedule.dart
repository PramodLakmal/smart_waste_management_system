import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/waste_collection_schedule.dart';
import '../../models/schedule_model.dart';

class UpdateSchedulePage extends StatefulWidget {
  final Schedule schedule;

  const UpdateSchedulePage({Key? key, required this.schedule}) : super(key: key);

  @override
  _UpdateSchedulePageState createState() => _UpdateSchedulePageState();
}

class _UpdateSchedulePageState extends State<UpdateSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String? _selectedWasteCollector;
  List<String> _wasteCollectors = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill form fields for editing
    _vehicleController.text = widget.schedule.vehicleNumber;
    _selectedWasteCollector = widget.schedule.wasteCollector; // Set the current collector
    _startDate = widget.schedule.startTime;
    _endDate = widget.schedule.endTime;
    _startTime = TimeOfDay.fromDateTime(widget.schedule.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.schedule.endTime);
    _fetchWasteCollectors(); // Fetch waste collectors on initialization
  }

  // Fetch waste collector names from Firestore
  Future<void> _fetchWasteCollectors() async {
    QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'wasteCollector')
        .get();

    List<String> collectors = [];
    for (var doc in collectorsSnapshot.docs) {
      collectors.add(doc['name'] as String);
    }

    setState(() {
      _wasteCollectors = collectors;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
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

      final updatedSchedule = Schedule(
        city: widget.schedule.city, // City cannot be changed
        vehicleNumber: _vehicleController.text,
        wasteCollector: _selectedWasteCollector!, // Use selected waste collector
        wasteCollectorId: widget.schedule.wasteCollectorId, // Add the required wasteCollectorId
        startTime: startDateTime,
        endTime: endDateTime,
        userIds: widget.schedule.userIds, // Keep existing user IDs
      );

      final scheduleData = updatedSchedule.toMap();

      // Update the existing schedule
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(widget.schedule.id) // Assuming you have the id in the schedule object
          .update(scheduleData);

      // Navigate to WasteCollectionSchedule after updating
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WasteCollectionSchedule()), // Make sure to import this page
      );
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
        title: Text('Update Schedule'),
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
                Text('City: ${widget.schedule.city}'), // Display the city as read-only
                const SizedBox(height: 8),
                
                _textField('Vehicle Number:', _vehicleController),
                const SizedBox(height: 8),
                
                // Waste Collector Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Waste Collector',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  value: _selectedWasteCollector,
                  items: _wasteCollectors
                      .map((collector) => DropdownMenuItem(value: collector, child: Text(collector)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWasteCollector = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a waste collector' : null,
                ),
                const SizedBox(height: 16),

                _dateTimeRow('Start Time:', _startDate, _startTime, isStart: true),
                const SizedBox(height: 16),
                _dateTimeRow('End Time:', _endDate, _endTime, isStart: false),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _submit,
                  child: Text('Update Schedule'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _dateTimeRow(String label, DateTime date, TimeOfDay time, {required bool isStart}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        TextButton(
          onPressed: () => _pickDate(isStartDate: isStart),
          child: Text(DateFormat('yyyy-MM-dd').format(date)),
        ),
        TextButton(
          onPressed: () => _pickTime(isStartTime: isStart),
          child: Text(time.format(context)),
        ),
      ],
    );
  }
}
