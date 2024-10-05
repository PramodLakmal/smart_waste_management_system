import 'package:flutter/material.dart';
import 'package:smart_waste_management_system/models/route_model.dart';
import 'package:smart_waste_management_system/screens/admin/driver_records_screen.dart';
import 'package:smart_waste_management_system/screens/admin/route_entry_screen.dart';
import 'package:smart_waste_management_system/screens/admin/waste_entry_screen.dart';
import 'package:smart_waste_management_system/services/route_service.dart';

class RouteMonitoringScreen extends StatefulWidget {
  @override
  _RouteMonitoringScreenState createState() => _RouteMonitoringScreenState();
}

class _RouteMonitoringScreenState extends State<RouteMonitoringScreen> {
  final RouteService _routeService = RouteService();
  late Future<List<RouteModel>> _routes;

  @override
  void initState() {
    super.initState();
    _routes = _routeService.getAllRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route Monitoring'),
      ),
      body: FutureBuilder<List<RouteModel>>(
        future: _routes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<RouteModel> routes = snapshot.data ?? [];

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              RouteModel route = routes[index];

              // Ensure driverId and routeId are non-null before proceeding
              String? driverName = route.driverName ?? 'Unknown';
              String? routeId = route.id ?? 'N/A';
              String? driverId = route.driverId ?? 'N/A';

              return ListTile(
                title: Text(route.routeName ?? 'Unknown Route'),
                subtitle: Text('Driver: $driverName  |  Vehicle: ${route.vehicleNumber ?? 'Unknown Vehicle'}'),
                onTap: () {
                  if (routeId != 'N/A') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WasteEntryScreen(routeId: route.id),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Route ID is missing. Cannot open waste entry screen.")),
                    );
                  }
                },
                trailing: IconButton(
                  icon: Icon(Icons.person),
                  onPressed: () {
                    
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverRecordsScreen(
                            routeId: route.id, driverId: '',
                          ),
                        ),
                      ); 
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RouteEntryScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
