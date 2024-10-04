import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile/profile_screen.dart'; // Import the ProfileScreen widget

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _selectedIndex == 0
            ? Text('Home Page Content')  // Replace with your actual home page content
            : ProfileScreen(),  // Show ProfileScreen widget in the same Scaffold
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
