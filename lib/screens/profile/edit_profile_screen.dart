import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userModel;

  EditProfileScreen({required this.userModel});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Create TextEditingController for each field
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Cities dropdown value
  late String _selectedCity;

  @override
  void initState() {
    super.initState();

    // Initialize the text controllers with the current values
    _nameController = TextEditingController(text: widget.userModel.name);
    _emailController = TextEditingController(text: widget.userModel.email);
    _phoneController = TextEditingController(text: widget.userModel.phone);
    _addressController = TextEditingController(text: widget.userModel.address);

    // Initialize the selected city with the user's current city or set default to "Malabe"
    _selectedCity = widget.userModel.city.isNotEmpty
        ? widget.userModel.city
        : 'Malabe'; // Default to "Malabe" if city is not provided
  }

  // Save changes to Firestore
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'city': _selectedCity, // Save selected city
        });

        // Show confirmation and pop the screen with true result
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
        Navigator.pop(context, true); // Return true to indicate the profile was updated
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(maxWidth: 600), // Restrict the form width on larger screens
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildTextField('Name', _nameController),
                _buildTextField('Email', _emailController, isEmail: true),
                _buildTextField('Phone', _phoneController),
                _buildTextField('Address', _addressController),
                _buildCityDropdown(), // Dropdown for city selection
                SizedBox(height: 20),
                _buildSaveButton(), // Custom save button
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build TextFormField for each field
  Widget _buildTextField(String label, TextEditingController controller, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Rounded border
          ),
        ),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  // Helper method to build the DropdownButtonFormField for city selection
  Widget _buildCityDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: _selectedCity, // Set initial selected value
        items: ['Malabe', 'Kaduwela'].map((String city) {
          return DropdownMenuItem<String>(
            value: city,
            child: Text(city),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: 'City',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Rounded border
          ),
        ),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCity = newValue!; // Update the selected city
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a city';
          }
          return null;
        },
      ),
    );
  }

  // Helper method to build the Save Changes button
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveChanges,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
        textStyle: TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Add rounded corners
        ),
        backgroundColor: Colors.blue, // Set the button color
      ),
      child: Text('Save Changes'),
    );
  }
}
