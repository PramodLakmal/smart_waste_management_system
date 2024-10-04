import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart'; // Import AuthService
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart'; // Import the UserModel
import 'edit_profile_screen.dart'; // Import the EditProfileScreen

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService(); // Create an instance of AuthService
  UserModel? _currentUserDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details on initialization
  }

  // Fetch currently logged-in user's details from Firestore
  Future<void> _fetchUserDetails() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _currentUserDetails = UserModel.fromDocument(userDoc); // Create a UserModel from the document
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              // Navigate to EditProfileScreen with user details
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(userModel: _currentUserDetails!),
                ),
              );

              // Check if the result is true, indicating the profile was updated
              if (result == true) {
                _fetchUserDetails(); // Reload user details
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
          : SingleChildScrollView( // Add scrolling capability
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildProfileCard(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.signOut(); // Sign out the user
                        Navigator.pushReplacementNamed(context, '/'); // Navigate to login page
                      },
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Method to build the profile card showing user details
  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(
                  _currentUserDetails!.name[0], // Display first letter of the name
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildInfoTile(Icons.person, 'Name', _currentUserDetails!.name),
            _buildInfoTile(Icons.email, 'Email', _currentUserDetails!.email),
            _buildInfoTile(Icons.phone, 'Phone', _currentUserDetails!.phone),
            _buildInfoTile(Icons.location_on, 'Address', _currentUserDetails!.address),
            _buildInfoTile(Icons.location_city, 'City', _currentUserDetails!.city),
            _buildInfoTile(Icons.map, 'State', _currentUserDetails!.state),
            _buildInfoTile(Icons.flag, 'Country', _currentUserDetails!.country),
            _buildInfoTile(Icons.markunread_mailbox, 'Postal Code', _currentUserDetails!.postalCode),
          ],
        ),
      ),
    );
  }

  // Method to build a ListTile for displaying user info
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value.isNotEmpty ? value : 'Not provided'),
    );
  }
}
