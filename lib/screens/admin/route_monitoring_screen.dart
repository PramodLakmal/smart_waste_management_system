import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_model.dart';
import '../../models/waste_record_model.dart';
import '../../services/waste_service.dart';
import 'waste_details_screen.dart';
import 'waste_entry_screen.dart';

class RouteMonitoringScreen extends StatefulWidget {
  final String routeId;
  final String wasteCollector;

  RouteMonitoringScreen({required this.routeId, required this.wasteCollector});

  @override
  _RouteMonitoringScreenState createState() => _RouteMonitoringScreenState();
}

class _RouteMonitoringScreenState extends State<RouteMonitoringScreen> {
  List<Schedule> _schedules = []; // List to hold the fetched schedules
  bool _isLoading = true; // To show loading indicator
  int? _selectedScheduleIndex; // To hold the selected schedule index
  final WasteService _wasteService = WasteService();

  @override
  void initState() {
    super.initState();
    _fetchSchedules(); // Fetch schedules when the screen is initialized
  }

  // Method to fetch all schedules from Firestore
  Future<void> _fetchSchedules() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('schedules').get();

      setState(() {
        _schedules = querySnapshot.docs
            .map((doc) => Schedule.fromFirestore(doc)) // Map Firestore documents to Schedule model
            .toList();
        _isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      // Handle any errors
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
        title: Text('Normal Schedule List', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Schedules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = _schedules[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.teal),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Row(
                              children: [
                                Radio(
                                  value: index,
                                  groupValue: _selectedScheduleIndex,
                                  activeColor: Colors.teal,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedScheduleIndex = value as int?;
                                    });
                                  },
                                ),
                                Text('${schedule.city} Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            subtitle: Text(
                              'Vehicle Number: ${schedule.vehicleNumber}\nWaste Collector: ${schedule.wasteCollector}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedScheduleIndex != null
                        ? () {
                            // Navigate to WasteDetailsScreen when a schedule is selected
                            _viewWasteDetails(_schedules[_selectedScheduleIndex!].wasteCollector);
                          }
                        : null, // Disable the button if no schedule is selected
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Start now',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _viewWasteDetails(String wasteCollector) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasteDetailsScreen(
          wasteCollector: wasteCollector,
        ),
      ),
    );
  }
}
