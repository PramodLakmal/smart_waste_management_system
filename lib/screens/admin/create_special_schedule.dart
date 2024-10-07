import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateSpecialSchedulePage extends StatefulWidget {
  final String requestId;
  final String city;
  final String scheduledDate;
  final String address;
  final List wasteTypes;

  CreateSpecialSchedulePage({
    required this.requestId,
    required this.city,
    required this.scheduledDate,
    required this.address,
    required this.wasteTypes,
  });

  @override
  _CreateSpecialSchedulePageState createState() => _CreateSpecialSchedulePageState();
}

class _CreateSpecialSchedulePageState extends State<CreateSpecialSchedulePage> {
  final TextEditingController _collectorController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();

  Future<void> _createSpecialSchedule() async {
    // Create the special schedule document in the 'specialschedule' collection
    await FirebaseFirestore.instance.collection('specialschedule').add({
      'requestId': widget.requestId,
      'city': widget.city,
      'scheduledDate': widget.scheduledDate,
      'address': widget.address,
      'wasteTypes': widget.wasteTypes,
      'wasteCollector': _collectorController.text,
      'vehicleNumber': _vehicleController.text,
      'status': 'schedule created',
    });

    // Update the status of the special waste request to 'schedule created'
    await FirebaseFirestore.instance
        .collection('specialWasteRequests')
        .doc(widget.requestId)
        .update({'status': 'schedule created'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Special schedule created successfully.')),
    );

    Navigator.pop(context); // Go back after creation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Special Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Pre-filled fields
            TextFormField(
              initialValue: widget.city,
              decoration: InputDecoration(labelText: 'City'),
              enabled: false,
            ),
            TextFormField(
              initialValue: widget.scheduledDate,
              decoration: InputDecoration(labelText: 'Scheduled Date'),
              enabled: false,
            ),
            TextFormField(
              initialValue: widget.address,
              decoration: InputDecoration(labelText: 'Address'),
              enabled: false,
            ),
            Text('Waste Types:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.wasteTypes.map((waste) {
              return Text('${waste['type']} - ${waste['weight']} kg');
            }).toList(),
            // Input fields for waste collector and vehicle number
            TextFormField(
              controller: _collectorController,
              decoration: InputDecoration(labelText: 'Waste Collector'),
            ),
            TextFormField(
              controller: _vehicleController,
              decoration: InputDecoration(labelText: 'Vehicle Number'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _createSpecialSchedule,
              child: Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
