import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart'; // For visualizing percentages
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/confirm_bin_screen.dart';
import '../screens/admin/waste_collection_requests_screen.dart';
import '../screens/admin/view_special_requests_screen.dart';
import '../screens/admin/waste_collection_schedule.dart';
import '../screens/admin/route_schedule_selection.dart';
import '../../models/schedule_model.dart';
import '../screens/profile/profile_screen.dart'; 

class HomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<Schedule?> _fetchSchedule() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('schedules').get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      return Schedule.fromFirestore(doc);
    }
    return null;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
      ),
      body: _buildBody(),
      bottomNavigationBar: !kIsWeb // Show BottomNavigationBar on mobile only
          ? BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            )
          : null, // For web, do not show BottomNavigationBar
      drawer: kIsWeb ? _buildSideNavBar() : null, // Side Nav for web
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildAdminGrid(); // Home screen content
    } else {
      return ProfileScreen(); // Show ProfileScreen when profile is selected
    }
  }

  Widget _buildAdminGrid() {
    // Responsive GridView for mobile and web
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = kIsWeb
            ? (constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 800
                    ? 3
                    : 2)
            : 2; // For mobile, we use 2 columns

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: EdgeInsets.all(10),
          children: [
            _buildAdminCard(
              icon: Icons.people,
              title: 'User Management',
              description: 'Manage Users in the System',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserManagementScreen()),
                );
              },
            ),
            _buildAdminCard(
              icon: Icons.add_box,
              title: 'Bin Registration',
              description: 'Review and Confirm Bins',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ConfirmBinScreen()),
                );
              },
            ),
            _buildAdminCard(
              icon: Icons.schedule,
              title: 'Waste Collection Schedule',
              description: 'Schedule Waste Collection',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WasteCollectionSchedule()),
                );
              },
            ),
            _buildAdminCard(
              icon: Icons.list,
              title: 'View Collection Requests',
              description: 'View all Waste Collection Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WasteCollectionRequestsScreen()),
                );
              },
            ),
            _buildAdminCard(
              icon: Icons.list,
              title: 'Special Collection Requests',
              description: '',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AdminViewRequestsScreen()),
                );
              },
            ),
            _buildAdminCard(
              icon: Icons.map,
              title: 'Route Monitoring',
              description: 'Monitor Waste Collection Routes',
              onTap: () async {
                Schedule? schedule = await _fetchSchedule();
                if (schedule != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ScheduleListScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No schedules found')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 300 : double.infinity),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavBar() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text('Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              setState(() {
                _selectedIndex = 0; // Set index to Home
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              setState(() {
                _selectedIndex = 1; // Set index to Profile
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
