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
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _collectorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      // Pre-fill form fields for editing
      _zoneController.text = widget.schedule!.collectionZone;
      _vehicleController.text = widget.schedule!.vehicleNumber;
      _collectorController.text = widget.schedule!.wasteCollector;
      _locationController.text = widget.schedule!.location;
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
  }

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

      final schedule = Schedule(
        id: widget.schedule?.id, // Add id for editing
        collectionZone: _zoneController.text,
        vehicleNumber: _vehicleController.text,
        wasteCollector: _collectorController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text,
      );

      if (widget.schedule == null) {
        // Create new schedule
        await FirebaseFirestore.instance.collection('schedules').add(schedule.toMap());
      } else {
        // Update existing schedule
        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(widget.schedule!.id)
            .update(schedule.toMap());
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Create New Schedule' : 'Edit Schedule'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                controller: _zoneController,
                decoration: InputDecoration(labelText: 'Collection Zone'),
                validator: (value) => value!.isEmpty ? 'Enter zone' : null,
              ),
              TextFormField(
                controller: _vehicleController,
                decoration: InputDecoration(labelText: 'Vehicle Number'),
                validator: (value) => value!.isEmpty ? 'Enter vehicle number' : null,
              ),
              TextFormField(
                controller: _collectorController,
                decoration: InputDecoration(labelText: 'Waste Collector'),
                validator: (value) => value!.isEmpty ? 'Enter collector name' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                  ElevatedButton(
                    onPressed: () => _pickDate(isStartDate: true),
                    child: Text('Select Date'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start Time: ${_startTime.format(context)}'),
                  ElevatedButton(
                    onPressed: () => _pickTime(isStartTime: true),
                    child: Text('Select Time'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('End Date: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                  ElevatedButton(
                    onPressed: () => _pickDate(isStartDate: false),
                    child: Text('Select Date'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('End Time: ${_endTime.format(context)}'),
                  ElevatedButton(
                    onPressed: () => _pickTime(isStartTime: false),
                    child: Text('Select Time'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.schedule == null ? 'Create Schedule' : 'Update Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
