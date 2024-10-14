import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/waste_collection_schedule.dart';
import '../../models/schedule_model.dart';

class UpdateSchedulePage extends StatefulWidget {
  final Schedule schedule;

  const UpdateSchedulePage({super.key, required this.schedule});

  @override
  _UpdateSchedulePageState createState() => _UpdateSchedulePageState();
}

class _UpdateSchedulePageState extends State<UpdateSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String? _selectedWasteCollector;
  String? _selectedWasteCollectorId;
  List<Map<String, String>> _wasteCollectors = [];

  // Color scheme
  final Color darkGreen = Color(0xFF2E7D32);
  final Color green = Color(0xFF4CAF50);
  final Color lightGreen = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    _selectedWasteCollector = widget.schedule.wasteCollector;
    _selectedWasteCollectorId = widget.schedule.wasteCollectorId;
    _startDate = widget.schedule.startTime;
    _endDate = widget.schedule.endTime;
    _startTime = TimeOfDay.fromDateTime(widget.schedule.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.schedule.endTime);
    _fetchWasteCollectors();
  }

  Future<void> _fetchWasteCollectors() async {
    QuerySnapshot collectorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'wasteCollector')
        .get();

    setState(() {
      _wasteCollectors = collectorsSnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      DateTime startDateTime = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _startTime.hour, _startTime.minute,
      );
      DateTime endDateTime = DateTime(
        _endDate.year, _endDate.month, _endDate.day,
        _endTime.hour, _endTime.minute,
      );

      final updatedSchedule = Schedule(
        city: widget.schedule.city,
        wasteCollector: _selectedWasteCollector!,
        wasteCollectorId: _selectedWasteCollectorId!,
        startTime: startDateTime,
        endTime: endDateTime,
        userIds: widget.schedule.userIds,
        bins: widget.schedule.bins,
        isScheduled: true,
      );

      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(widget.schedule.id)
          .update(updatedSchedule.toMap());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WasteCollectionSchedule()),
      );
    }
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
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
        title: Text('Update Schedule', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: darkGreen,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightGreen.withOpacity(0.2), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: 'City and Waste Collector',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City: ${widget.schedule.city}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: darkGreen),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Waste Collector',
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
                            labelStyle: TextStyle(color: green),
                          ),
                          value: _selectedWasteCollector,
                          items: _wasteCollectors
                              .map((collector) => DropdownMenuItem(
                                    value: collector['name'],
                                    child: Text(collector['name']!),
                                    onTap: () {
                                      _selectedWasteCollectorId = collector['id'];
                                    },
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedWasteCollector = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a waste collector' : null,
                          dropdownColor: Colors.white,
                          style: TextStyle(color: darkGreen),
                          icon: Icon(Icons.arrow_drop_down, color: green),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildCard(
                    title: 'Schedule',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateTimeField('Start Time', _startDate, _startTime, true),
                        SizedBox(height: 16),
                        _buildDateTimeField('End Time', _endDate, _endTime, false),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        elevation: 5,
                      ),
                      child: Text(
                        'Update Schedule',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget content}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: darkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String label, DateTime date, TimeOfDay time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: darkGreen)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStartDate: isStart),
                icon: Icon(Icons.calendar_today, color: green),
                label: Text(DateFormat('yyyy-MM-dd').format(date), style: TextStyle(color: darkGreen)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: green),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: green),
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