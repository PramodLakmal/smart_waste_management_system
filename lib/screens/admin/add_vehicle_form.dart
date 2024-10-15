import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehicleForm extends StatefulWidget {
  const AddVehicleForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  // Color scheme
  final Color primaryColor = Color(0xFF2E7D32);
  final Color secondaryColor = Color(0xFF4CAF50);
  final Color backgroundColor = Colors.grey[200]!;
  final Color accentColor = Colors.red[100]!;
  final Color cardColor = Color(0xFF81C784);

  // Function to add a vehicle to Firestore
  Future<void> _addVehicle() async {
    if (_formKey.currentState!.validate()) {
      String vehicleId = _vehicleIdController.text;
      String driverName = _driverNameController.text;
      String status = _statusController.text;
      double latitude = double.parse(_latitudeController.text);
      double longitude = double.parse(_longitudeController.text);

      try {
        await _firestore.collection('vehicleTracking').doc(vehicleId).set({
          'vehicleId': vehicleId,
          'driverName': driverName,
          'status': status,
          'location': GeoPoint(latitude, longitude),
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle Added Successfully!'),
            backgroundColor: secondaryColor,
          ),
        );
        _formKey.currentState!.reset(); // Reset form after submission
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add vehicle. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: secondaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Add New Vehicle', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _vehicleIdController,
                            label: 'Vehicle ID',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a vehicle ID';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _driverNameController,
                            label: 'Driver Name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter driver\'s name';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _statusController,
                            label: 'Vehicle Status',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter vehicle status';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _latitudeController,
                            label: 'Latitude',
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
                          _buildTextField(
                            controller: _longitudeController,
                            label: 'Longitude',
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Add Vehicle',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
}