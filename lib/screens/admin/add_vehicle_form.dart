import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehicleForm extends StatefulWidget {
  @override
  _AddVehicleFormState createState() => _AddVehicleFormState();
}

class _AddVehicleFormState extends State<AddVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleIdController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to add a vehicle to Firestore
  Future<void> _addVehicle() async {
    if (_formKey.currentState!.validate()) {
      String vehicleId = _vehicleIdController.text;
      String driverName = _driverNameController.text;
      String status = _statusController.text;
      double latitude = double.parse(_latitudeController.text);
      double longitude = double.parse(_longitudeController.text);

      await _firestore.collection('vehicleTracking').doc(vehicleId).set({
        'vehicleId': vehicleId,
        'driverName': driverName,
        'status': status,
        'location': GeoPoint(latitude, longitude),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vehicle Added Successfully!')));
      _formKey.currentState!.reset(); // Reset form after submission
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Vehicle'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _vehicleIdController,
                decoration: InputDecoration(labelText: 'Vehicle ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a vehicle ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _driverNameController,
                decoration: InputDecoration(labelText: 'Driver Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter driver\'s name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _statusController,
                decoration: InputDecoration(labelText: 'Vehicle Status'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle status';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter latitude';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter longitude';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addVehicle,
                child: Text('Add Vehicle'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}