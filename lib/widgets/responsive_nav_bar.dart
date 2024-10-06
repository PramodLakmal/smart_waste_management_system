import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResponsiveNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  ResponsiveNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  _ResponsiveNavBarState createState() => _ResponsiveNavBarState();
}

class _ResponsiveNavBarState extends State<ResponsiveNavBar> {
  String userRole = ''; // This will store the user's role

  @override
  void initState() {
    super.initState();
    _fetchUserRole(); // Fetch the role when the nav bar is initialized
  }

  Future<void> _fetchUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch the user role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        userRole = userDoc['role'] ?? 'guest'; // Default to 'guest' if no role
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildSideNav(context) : _buildBottomNav();
  }

  // Bottom navigation bar for mobile
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        if (userRole == 'user') // Only show this item if the role is 'user'
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'View Requests',
          ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
      currentIndex: widget.selectedIndex,
      onTap: widget.onItemTapped,
    );
  }

  // Side navigation bar (drawer) for web
  Widget _buildSideNav(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: widget.selectedIndex == 0,
            onTap: () {
              widget.onItemTapped(0);
              Navigator.pop(context); // Close drawer after tapping
            },
          ),
          if (userRole == 'user') // Show this option only if the role is 'user'
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('View Requests'),
              selected: widget.selectedIndex == 1,
              onTap: () {
                widget.onItemTapped(1);
                Navigator.pop(context); // Close drawer after tapping
              },
            ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            selected: widget.selectedIndex == 2,
            onTap: () {
              widget.onItemTapped(2);
              Navigator.pop(context); // Close drawer after tapping
            },
          ),
        ],
      ),
    );
  }
}
