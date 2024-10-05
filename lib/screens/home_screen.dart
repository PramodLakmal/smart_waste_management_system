import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:smart_waste_management_system/screens/admin/schedule_waste_collection.dart';
import '../widgets/responsive_nav_bar.dart'; // Import the responsive nav bar
import '../screens/profile/profile_screen.dart';
import '../screens/admin/user_management_screen.dart'; // Import the UserManagementScreen
import 'admin/route_monitoring_screen.dart'; // Import the RouteMonitoringScreen
import '../screens/admin/schedule_waste_collection.dart'; // Import WasteCollectionDashboard


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false; // To check if the user is an admin

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // Check if the user is an admin
  }

  // Check if the logged-in user is an admin
  Future<void> _checkAdminStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _isAdmin = userDoc['role'] == 'admin'; // Assuming 'role' field contains the user role
      });
    }
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
        title: Text('Home'),
      ),
      drawer: kIsWeb
          ? ResponsiveNavBar(
              // Drawer for web
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null, // No drawer on mobile, use bottom nav instead
      body: Center(
        child: _selectedIndex == 0
            ? _buildHomeContent() // Call method to build home content
            : ProfileScreen(),
      ),
      bottomNavigationBar: !kIsWeb
          ? ResponsiveNavBar(
              // Bottom navigation for mobile
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null, // No bottom nav on web, use drawer instead
    );
  }

  // Method to build the content for the home page
  Widget _buildHomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Welcome to the Waste Management System',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        if (_isAdmin) ...[
          // Display buttons only if the user is an admin
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        UserManagementScreen()), // Navigate to UserManagementScreen
              );
            },
            child: Text('User Management'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WasteCollectionSchedule(), // Navigate to WasteCollectionDashboard
                ),
              );
            },
            child: Text('Schedule Waste Collections'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Navigate to Waste Collection Requests
            },
            child: Text('Waste Collection Requests'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        RouteMonitoringScreen()), // Navigate to RouteMonitoringScreen
              );
            },
            child: Text('Route Monitoring'),
          ),
        ],
        // Optionally, display a message if the user is not an admin
        if (!_isAdmin)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'You do not have access to management features.',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
