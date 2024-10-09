import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteEntryScreen extends StatefulWidget {
  final String routeId;
  final String wasteCollector;
  String vehicleNumber;

  WasteEntryScreen({required this.routeId, required this.wasteCollector, required this.vehicleNumber});

  @override
  _WasteEntryScreenState createState() => _WasteEntryScreenState();
}

class _WasteEntryScreenState extends State<WasteEntryScreen> {
  @override
  void initState() {
    super.initState();
    _fetchVehicleNumber();
  }

  Future<void> _fetchVehicleNumber() async {
    // Fetch the vehicle number based on the routeId
    // Adjust your Firestore query as needed
    DocumentSnapshot snapshot = (await FirebaseFirestore.instance
        .collection('schedules')
        .get()) as DocumentSnapshot<Object?>;

    if (snapshot.exists) {
      setState(() {
        widget.vehicleNumber = snapshot['vehicleNumber']; // Ensure the field matches your Firestore schema
      });
    }
  }
  final _formKey = GlobalKey<FormState>();
  String? _wasteType;
  double? _wasteWeight;

  // Method to save the waste entry to Firestore
  Future<void> _saveWasteEntry() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseFirestore.instance.collection('waste_entries').add({
          'routeId': widget.routeId,
          'wasteCollector': widget.wasteCollector,
          'vehicleNumber': widget.vehicleNumber, // Using passed vehicle number
          'wasteType': _wasteType,
          'wasteWeight': _wasteWeight,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waste entry added successfully!')),
        );

        Navigator.pop(context); // Go back after saving
      } catch (e) {
        print('Error adding waste entry: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add waste entry')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Waste Entry',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown for Waste Type
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Waste Type'),
                items: ['Organic', 'Plastic', 'Metal', 'Glass', 'E-waste']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _wasteType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a waste type' : null,
              ),
              SizedBox(height: 16),
              // Input field for Waste Weight
              TextFormField(
                decoration: InputDecoration(labelText: 'Waste Weight (kg)'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _wasteWeight = double.tryParse(value ?? '0');
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter the weight'
                    : null,
              ),
              SizedBox(height: 32),
              // Submit button
              ElevatedButton(
                onPressed: _saveWasteEntry,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text('Submit Entry',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
