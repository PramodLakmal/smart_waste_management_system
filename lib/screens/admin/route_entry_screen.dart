import 'package:flutter/material.dart';
import 'package:smart_waste_management_system/models/route_model.dart';
import 'package:smart_waste_management_system/services/route_service.dart';

class RouteEntryScreen extends StatefulWidget {
  const RouteEntryScreen({super.key});

  @override
  _RouteEntryScreenState createState() => _RouteEntryScreenState();
}

class _RouteEntryScreenState extends State<RouteEntryScreen> {
  final RouteService _routeService = RouteService();
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();

  void _saveRoute() async {
    String routeName = _routeNameController.text;
    String driverName = _driverNameController.text;
    String vehicleNumber = _vehicleNumberController.text;

    if (routeName.isNotEmpty && driverName.isNotEmpty && vehicleNumber.isNotEmpty) {
      RouteModel newRoute = RouteModel(
        routeName: routeName,
        driverName: driverName,
        vehicleNumber: vehicleNumber,
      );

      await _routeService.addRoute(newRoute);
      Navigator.pop(context);
    } else {
      // Handle empty fields
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Route Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _routeNameController,
              decoration: InputDecoration(labelText: 'Route Name'),
            ),
            TextField(
              controller: _driverNameController,
              decoration: InputDecoration(labelText: 'Driver Name'),
            ),
            TextField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(labelText: 'Vehicle Number'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRoute,
              child: Text('Save Route'),
            ),
          ],
        ),
      ),
    );
  }
}
