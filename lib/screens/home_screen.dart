import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../widgets/responsive_nav_bar.dart'; // Import the responsive nav bar
import '../screens/profile/profile_screen.dart';

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
      appBar: AppBar(
      ),
      drawer: kIsWeb
          ? ResponsiveNavBar( // Drawer for web
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null, // No drawer on mobile, use bottom nav instead
      body: Center(
        child: _selectedIndex == 0
            ? Text('Home Page')
            : ProfileScreen(),
      ),
      bottomNavigationBar: !kIsWeb
          ? ResponsiveNavBar( // Bottom navigation for mobile
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null, // No bottom nav on web, use drawer instead
    );
  }
}
