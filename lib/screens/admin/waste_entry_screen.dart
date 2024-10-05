import 'package:flutter/material.dart';
import 'package:smart_waste_management_system/models/waste_record_model.dart';
import 'package:smart_waste_management_system/services/waste_service.dart';

class WasteEntryScreen extends StatefulWidget {
  final String routeId;

  WasteEntryScreen({required this.routeId});

  @override
  _WasteEntryScreenState createState() => _WasteEntryScreenState();
}

class _WasteEntryScreenState extends State<WasteEntryScreen> {
  final WasteService _wasteService = WasteService();
  final TextEditingController _wasteTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  void _saveWasteRecord() async {
    String wasteType = _wasteTypeController.text;
    double? weight = double.tryParse(_weightController.text);

    if (wasteType.isNotEmpty && weight != null) {
      WasteRecord newWasteRecord = WasteRecord(
        wasteType: wasteType,
        weight: weight,
        routeId: widget.routeId,
        status: 'pending', // Default status
      );

      await _wasteService.addWasteRecord(newWasteRecord);
      Navigator.pop(context);
    } else {
      // Handle empty fields or invalid weight
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter valid waste details.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Waste Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _wasteTypeController,
              decoration: InputDecoration(labelText: 'Waste Type'),
            ),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveWasteRecord,
              child: Text('Save Waste Record'),
            ),
          ],
        ),
      ),
    );
  }
}
