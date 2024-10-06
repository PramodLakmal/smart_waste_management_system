import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/screens/admin/route_monitoring_screen.dart';
import '../../models/schedule_model.dart';

class RouteScheduleSelection extends StatefulWidget {
  const RouteScheduleSelection({Key? key}) : super(key: key);
  
  @override
  _RouteScheduleSelectionState createState() => _RouteScheduleSelectionState();
}

class _RouteScheduleSelectionState extends State<RouteScheduleSelection> {
  List<Schedule> _schedules = []; // List to hold the fetched schedules
  bool _isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    _fetchSchedules(); // Fetch schedules when the screen is initialized
  }

  // Method to fetch all schedules from Firestore
  Future<void> _fetchSchedules() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('schedules').get();

      setState(() {
        _schedules = querySnapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList(); // Map Firestore documents to Schedule model
        _isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      print("Error fetching schedules: $e");
      setState(() {
        _isLoading = false; // Stop loading if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Schedules', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.teal),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    child: ListTile(
                      title: Text('Normal Schedule',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text('Employees can work as usual'),
                      onTap: () {
                        // Navigate back to the Route Monitoring Screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteMonitoringScreen(routeId: '', wasteCollector: '',), // Replace with your actual Route Monitoring Screen
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.teal),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    child: ListTile(
                      title: Text('Special Schedule',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text('Employees can work in set schedule'),
                      onTap: () {
                        // Navigate back to the Route Monitoring Screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteMonitoringScreen(routeId: '', wasteCollector: '',), // Replace with your actual Route Monitoring Screen
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
