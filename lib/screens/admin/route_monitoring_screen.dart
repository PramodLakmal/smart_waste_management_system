import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/models/special_schedule_model.dart';
import 'package:smart_waste_management_system/screens/admin/waste_entry_screen.dart'; // New Waste Entry Screen
import 'package:smart_waste_management_system/screens/admin/waste_summary_screen.dart'; // New Waste Summary Screen
import '../../models/schedule_model.dart';

class RouteMonitoringScreen extends StatefulWidget {
  final String routeId;
  final String wasteCollector;

  const RouteMonitoringScreen({
    super.key,
    required this.routeId,
    required this.wasteCollector,
  });

  @override
  _RouteMonitoringScreenState createState() => _RouteMonitoringScreenState();
}

class _RouteMonitoringScreenState extends State<RouteMonitoringScreen> {
  List<Schedule> _schedules = []; // List to hold the fetched schedules
  List<SpecialSchedule> _specialSchedules = []; // List to hold the fetched special schedules
  bool _isLoading = true; // To show loading indicator
  int? _selectedScheduleIndex; // To hold the selected schedule index
  bool _isSpecialSchedule = false; // Whether user selected Special Schedule

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchSpecialSchedules(); // Fetch special schedules when the screen is initialized
  }

  // Method to fetch all schedules from Firestore
  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true; // Set loading to true before starting to fetch
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('schedules').get();

      setState(() {
        _schedules = querySnapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
        _isLoading = false; // Set loading to false after fetching
      });
    } catch (e) {
      print("Error fetching schedules: $e");
      setState(() {
        _isLoading = false; // Handle the error by setting loading to false
      });
    }
  }

  // Method to fetch all special schedules from Firestore
  Future<void> _fetchSpecialSchedules() async {
    setState(() {
      _isLoading = true; // Set loading to true before starting to fetch
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('specialschedule').get();
      print("Fetched special schedules: ${querySnapshot.docs.length}"); // Debugging line

      setState(() {
        _specialSchedules = querySnapshot.docs
            .map((doc) => SpecialSchedule.fromFirestore(doc)) // Map Firestore documents to SpecialSchedule model
            .toList();
        _isLoading = false; // Set loading to false after fetching
      });
    } catch (e) {
      print("Error fetching special schedules: $e");
      setState(() {
        _isLoading = false; // Handle the error by setting loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSpecialSchedule ? 'Special Schedule List' : 'Normal Schedule List',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _isSpecialSchedule
                          ? _specialSchedules.length
                          : _schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = _isSpecialSchedule
                            ? _specialSchedules[index] as SpecialSchedule
                            : _schedules[index] as Schedule;

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
                                Text(
                                  '${(schedule is Schedule) ? schedule.collectionZone : (schedule as SpecialSchedule).city} Route',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Vehicle Number: ${(schedule is Schedule) ? schedule.vehicleNumber : (schedule as SpecialSchedule).vehicleNumber}\nWaste Collector: ${(schedule is Schedule) ? schedule.wasteCollector : (schedule as SpecialSchedule).wasteCollector}',
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
                            if (_isSpecialSchedule) {
                              _viewWasteEntryScreen(
                                  _specialSchedules[_selectedScheduleIndex!]
                                      .wasteCollector);
                            } else {
                              _viewWasteEntryScreen(
                                  _schedules[_selectedScheduleIndex!]
                                      .wasteCollector);
                            }
                          }
                        : null, // Disable the button if no schedule is selected
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
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
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _viewWasteSummaryScreen(); // Show summary report
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'View Summary Report',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Change state to special schedule mode
                      setState(() {
                        _isSpecialSchedule = !_isSpecialSchedule;
                        _isLoading = true; // Set loading true when toggling
                      });
                      if (_isSpecialSchedule) {
                        _fetchSpecialSchedules();
                      } else {
                        _fetchSchedules();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _isSpecialSchedule
                            ? 'Back to Normal Schedule'
                            : 'View Special Schedule',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _viewWasteEntryScreen(String wasteCollector) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasteEntryScreen(
          routeId: widget.routeId,
          wasteCollector: wasteCollector,
          vehicleNumber: _isSpecialSchedule
              ? _specialSchedules[_selectedScheduleIndex!].vehicleNumber
              : _schedules[_selectedScheduleIndex!].vehicleNumber,
        ),
      ),
    );
  }

  void _viewWasteSummaryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasteSummaryScreen(
          schedules: _isSpecialSchedule ? _specialSchedules : _schedules, routeId: '',
        ),
      ),
    );
  }
}
