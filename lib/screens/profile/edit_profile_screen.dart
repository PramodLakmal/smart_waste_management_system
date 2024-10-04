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
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();

    // Initialize the text controllers with the current values
    _nameController = TextEditingController(text: widget.userModel.name);
    _emailController = TextEditingController(text: widget.userModel.email);
    _phoneController = TextEditingController(text: widget.userModel.phone);
    _addressController = TextEditingController(text: widget.userModel.address);
    _cityController = TextEditingController(text: widget.userModel.city);
    _stateController = TextEditingController(text: widget.userModel.state);
    _countryController = TextEditingController(text: widget.userModel.country);
    _postalCodeController = TextEditingController(text: widget.userModel.postalCode);
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
          'city': _cityController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'postalCode': _postalCodeController.text,
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
                _buildTextField('City', _cityController),
                _buildTextField('State', _stateController),
                _buildTextField('Country', _countryController),
                _buildTextField('Postal Code', _postalCodeController),
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
