import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? userModel; // Nullable UserModel
  final UserService _userService = UserService();
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load the user profile from Firestore
  void _loadUserProfile() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user ID

    if (userId.isNotEmpty) { // Ensure userId is not empty
      UserModel? user = await _userService.getUserById(userId);
      setState(() {
        userModel = user; // Assign the user data to userModel
        isLoading = false; // Set loading to false
      });
    } else {
      // Handle case where user is not logged in
      setState(() {
        isLoading = false; // Set loading to false
      });
      print("User is not logged in.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: isLoading // Check loading state
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching
          : userModel != null // Check if userModel is not null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${userModel!.name}', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 10),
                      Text('Email: ${userModel!.email}', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 10),
                      Text('Phone: ${userModel!.phone}', style: TextStyle(fontSize: 20)),
                      // Display other user details like address, role, etc.
                    ],
                  ),
                )
              : Center(child: Text('User data not found.')),
    );
  }
}
