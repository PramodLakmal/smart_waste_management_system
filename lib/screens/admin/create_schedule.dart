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
        id: widget.schedule?.id,
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
                _textField('Collection Zone:', _zoneController),
                const SizedBox(height: 8),
                _textField('Vehicle Number:', _vehicleController),
                const SizedBox(height: 8),
                _textField('Waste Collector:', _collectorController),
                const SizedBox(height: 8),
                _textField('Location:', _locationController),
                const SizedBox(height: 16),
                
                _dateTimeRow('Start Time:', _startDate, _startTime, () => _pickDate(isStartDate: true), () => _pickTime(isStartTime: true)),
                const SizedBox(height: 8),
                
                _dateTimeRow('End Time:', _endDate, _endTime, () => _pickDate(isStartDate: false), () => _pickTime(isStartTime: false)),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Edit Button
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(widget.schedule == null ? Icons.add : Icons.edit),
                      label: Text(widget.schedule == null ? 'Create Schedule' : 'Update Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 51, 126, 201),
                      ),
                    ),
                    
                    // Delete Button
                    // if (widget.schedule != null)
                    //   ElevatedButton.icon(
                    //     onPressed: () {
                    //       // Delete Functionality here
                    //     },
                    //     icon: Icon(Icons.delete),
                    //     label: Text('Delete'),
                    //     style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    //   ),
                  ],
                ),
                
                // Back Button
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
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
