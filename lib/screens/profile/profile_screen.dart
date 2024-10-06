import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart'; // Import AuthService
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart'; // Import the UserModel
import 'edit_profile_screen.dart'; // Import the EditProfileScreen
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../bin/update_bin_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService =
      AuthService(); // Create an instance of AuthService
  UserModel? _currentUserDetails;
  bool _isLoading = true;

  // Variables to control the collapse/expand state
  bool _isProfileExpanded = false;
  bool _isBinsExpanded = false;
  bool _isAdmin = false; // To track if the user is an admin

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
        _currentUserDetails = UserModel.fromDocument(
            userDoc); // Create a UserModel from the document
        _isAdmin =
            userDoc['role'] == 'admin'; // Determine if the user is an admin
        _isLoading = false;
      });
    }
  }

  // Handle the back button press to navigate to the home screen
  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(
        context, '/home'); // Navigate to home when back is pressed
    return false; // Prevent default back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        body: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator()) // Show loading spinner while fetching data
            : SingleChildScrollView(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    constraints: BoxConstraints(
                        maxWidth: 600), // Constrain width for larger screens
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Collapsible My Profile section
                        _buildCollapsibleSection(
                          title: 'My Profile',
                          isExpanded: _isProfileExpanded,
                          onExpandToggle: () {
                            setState(() {
                              _isProfileExpanded = !_isProfileExpanded;
                            });
                          },
                          child: _isProfileExpanded
                              ? _buildProfileDetails() // Show profile details when expanded
                              : SizedBox
                                  .shrink(), // Collapse the profile details
                        ),

                        SizedBox(height: 20),

                        // Collapsible My Bins section (only for users)
                        if (!_isAdmin) // Show My Bins only for regular users
                          _buildCollapsibleSection(
                            title: 'My Bins',
                            isExpanded: _isBinsExpanded,
                            onExpandToggle: () {
                              setState(() {
                                _isBinsExpanded = !_isBinsExpanded;
                              });
                            },
                            child: _isBinsExpanded
                                ? _buildBinList() // Show list of bins when expanded
                                : SizedBox.shrink(), // Collapse the bin list
                          ),

                        SizedBox(height: 20),

                        _buildSignOutButton(), // Modern Sign Out button
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Collapsible section widget
  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onExpandToggle,
    required Widget child,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.green,
            ),
            onTap: onExpandToggle, // Toggle the expand/collapse
          ),
          if (isExpanded) child, // Show content if expanded
        ],
      ),
    );
  }

  // Method to build profile details when expanded
  Widget _buildProfileDetails() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green,
            child: Text(
              _currentUserDetails!.name[0], // Display first letter of the name
              style: TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          SizedBox(height: 20),
          Text(
            _currentUserDetails!.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Divider(),
          _buildInfoTile(Icons.email, 'Email', _currentUserDetails!.email),
          _buildInfoTile(Icons.phone, 'Phone', _currentUserDetails!.phone),
          _buildInfoTile(
              Icons.location_on, 'Address', _currentUserDetails!.address),
          _buildInfoTile(
              Icons.location_city, 'City', _currentUserDetails!.city),

          // Edit Profile Button inside My Profile
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              // Navigate to EditProfileScreen with user details
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(userModel: _currentUserDetails!),
                ),
              );

              // Check if the result is true, indicating the profile was updated
              if (result == true) {
                _fetchUserDetails(); // Reload user details
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent, // Set button color
              foregroundColor: Colors.white, // Set text color
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Add rounded corners
              ),
            ),
            child: Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

// Method to build the list of bins when expanded
  Widget _buildBinList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bins')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final bins = snapshot.data!.docs;
          if (bins.isEmpty) {
            return Column(
              children: [
                Text('No bins added yet.'),
                SizedBox(height: 20),
                // Add Bin button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/add-bin'); // Navigate to Add Bin screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Set button color
                    foregroundColor: Colors.white, // Set text color
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Add rounded corners
                    ),
                  ),
                  child: Text('Add Bin'),
                ),
              ],
            );
          }
          return Column(
            children: [
              ...bins.map((bin) {
                return ListTile(
                  leading: Icon(Icons.delete, color: Colors.green),
                  title: Text(bin['nickname']),
                  subtitle: Text('Type: ${bin['type']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Navigate to EditBinScreen with bin data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditBinScreen(binData: bin),
                        ),
                      );
                    },
                    child: Text('Edit'),
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
              // Add Bin button at the end of the bin list
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                      context, '/add-bin'); // Navigate to Add Bin screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // Set button color
                  foregroundColor: Colors.white, // Set text color
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Add rounded corners
                  ),
                ),
                child: Text('Add Bin'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Modern Sign Out button
  Widget _buildSignOutButton() {
    return ElevatedButton(
      onPressed: () async {
        await _authService.signOut(); // Sign out the user
        Navigator.pushReplacementNamed(context, '/'); // Navigate to login page
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // Set button color to red
        foregroundColor: Colors.white, // Set text color
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        textStyle: TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Add rounded corners
        ),
      ),
      child: Text('Sign Out'),
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
