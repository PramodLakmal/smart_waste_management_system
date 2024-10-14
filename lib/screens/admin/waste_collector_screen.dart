import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_screen.dart';
import 'bin_summary_screen.dart';
import 'route_monitoring_screen.dart';
import 'special_schedule_screen.dart';

class WasteCollectorScreen extends StatefulWidget {
  const WasteCollectorScreen({super.key});

  @override
  _WasteCollectorScreenState createState() => _WasteCollectorScreenState();
}

class _WasteCollectorScreenState extends State<WasteCollectorScreen> {
  List<QueryDocumentSnapshot> _schedules = [];
  String? _wasteCollectorId;
  String? _selectedScheduleId; // State variable to store selected schedule ID
  final User? user = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  void _fetchCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _wasteCollectorId = user.uid;
      _fetchSchedules();
    } else {
      print("No user is logged in");
      // Optionally, navigate to login screen or show a message
    }
  }

  Future<void> _fetchSchedules() async {
    if (_wasteCollectorId == null) return;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('wasteCollectorId', isEqualTo: _wasteCollectorId)
          .get();
      setState(() {
        _schedules = querySnapshot.docs.isNotEmpty ? querySnapshot.docs : [];
      });
    } catch (e) {
      print("Error fetching schedules: $e");
      // Optionally, show an error message to the user
    }
  }

  Widget _buildScheduleList() {
    if (_schedules.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _schedules.length,
            itemBuilder: (context, index) {
              var schedule = _schedules[index].data() as Map<String, dynamic>;
              var wasteCollector = schedule['wasteCollector'];
              var city = schedule['city'];
              String scheduleId = _schedules[index].id; // Get the document ID

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.grey[200],
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    '$city Route',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text('Waste Collector: $wasteCollector'),
                    ],
                  ),
                  leading: Radio<String>(
                    value: scheduleId, // Use schedule ID as the value
                    groupValue: _selectedScheduleId, // Group value is the selected ID
                    activeColor: Color(0xFF4CAF50),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedScheduleId = value;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: (_selectedScheduleId == null)
                    ? null
                    : () {
                        // Attempt to find the selected schedule
                        try {
                          var selectedSchedule = _schedules.firstWhere(
                              (doc) => doc.id == _selectedScheduleId);

                          var scheduleData =
                              selectedSchedule.data() as Map<String, dynamic>;

                          if (scheduleData['bins'] != null &&
                              scheduleData['bins'] is List) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BinIdsScreen(
                                  binIds:
                                      List<String>.from(scheduleData['bins']),
                                  wasteCollector:
                                      scheduleData['wasteCollector'],
                                  wasteCollectorId:
                                      _wasteCollectorId ?? '', // Ensure non-null
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Invalid schedule data. Please select a valid schedule.')),
                            );
                          }
                        } catch (e) {
                          // Handle the case where no matching schedule is found
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Selected schedule not found. Please try again.')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Start Now'),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BinSummaryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('View Summary Report'),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpecialSchedulePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF81C784),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('View Special Schedule'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreen() {
    return ProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Collector App',
            style: TextStyle(color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white, // Set AppBar color if needed
        iconTheme: IconThemeData(color: Color(0xFF2E7D32)), // Icon color
      ),
      body: _currentIndex == 0 ? _buildScheduleList() : _buildProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
