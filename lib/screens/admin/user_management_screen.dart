import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/edit_profile_screen.dart'; // Ensure to import the edit profile screen
import '../../models/user_model.dart'; // Ensure to import UserModel

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = []; // List to hold user data
  List<UserModel> _filteredUsers = []; // List for filtered user data
  bool _isLoading = true;
  String _searchQuery = ''; // Store the search query

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users on initialization
  }

  // Fetch users from Firestore
  Future<void> _fetchUsers() async {
    try {
      QuerySnapshot userCollection = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users = userCollection.docs.map((doc) => UserModel.fromDocument(doc)).toList(); // Convert to UserModel
        _filteredUsers = _users; // Initialize filtered users
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  // Delete a user
  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      _fetchUsers(); // Refresh the user list
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User deleted successfully')));
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
    }
  }

  // Method to filter users based on search query
  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users; // Show all users if query is empty
      });
    } else {
      setState(() {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(query.toLowerCase()) ||
                 user.email.toLowerCase().contains(query.toLowerCase());
        }).toList(); // Filter users based on query
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _users.isEmpty
                ? Text('No users found.')
                : _buildSearchAndUserList(),
      ),
    );
  }

  // Method to build the search input and user list
  Widget _buildSearchAndUserList() {
    return Container(
      width: 600, // Fixed width for web view
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by name or email',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value; // Update the search query
              _filterUsers(_searchQuery); // Filter the users based on query
            },
          ),
          SizedBox(height: 16), // Space between search field and list
          Expanded(
            child: ListView(
              children: _filteredUsers.map((user) {
                return _buildUserCard(user);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build the user card
  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      child: ListTile(
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            SizedBox(height: 4),
            Text(
              'Role: ${user.role}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: user.role == 'admin' ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userModel: user), // Pass the UserModel
                  ),
                ).then((result) {
                  if (result == true) {
                    _fetchUsers(); // Refresh the user list
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Show a confirmation dialog before deleting
                _showDeleteConfirmationDialog(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Method to show the confirmation dialog
  void _showDeleteConfirmationDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteUser(user.uid); // Delete the user
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
