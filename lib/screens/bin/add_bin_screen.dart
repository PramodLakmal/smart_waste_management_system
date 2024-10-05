import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For image upload
import 'dart:io'; // For File type
import 'package:image_picker/image_picker.dart'; // For picking images

class AddBinScreen extends StatefulWidget {
  @override
  _AddBinScreenState createState() => _AddBinScreenState();
}

class _AddBinScreenState extends State<AddBinScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedBinType = 'Electrical Waste'; // Default bin type
  String _nickname = '';
  String _description = '';
  double _weight = 0.0;
  File? _imageFile; // To store the selected image
  final picker = ImagePicker();

  Future<void> _selectImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addBin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      // Reference to the Firestore collection
      CollectionReference bins = FirebaseFirestore.instance.collection('bins');

      // Create a new document reference, letting Firestore generate the ID
      DocumentReference newBinRef = bins.doc();

      // Upload the image to Firebase Storage if available
      String? imageUrl;
      if (_imageFile != null) {
        String imagePath = 'bin_images/${newBinRef.id}.jpg';
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref(imagePath)
            .putFile(_imageFile!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Prepare bin data
      Map<String, dynamic> binData = {
        'userId': userId, // Store the correct user ID
        'binId': newBinRef.id, // Use the document ID as the bin ID
        'type': _selectedBinType,
        'nickname': _nickname,
        'description': _description,
        'weight': _weight,
        'imageUrl': imageUrl,
        'filledPercentage': 0, // Initially set to 0 (can be updated later)
        'createdAt': FieldValue.serverTimestamp(), // Store creation time
        'confirmed': false, // Admin needs to confirm it
        'collectionRequestSent': false
      };

      // Add the bin to Firestore
      await newBinRef.set(binData);

      // Navigate back or show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bin added successfully!'),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Bin'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Bin Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBinType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBinType = newValue!;
                  });
                },
                items: ['Electrical Waste', 'Plastic Waste', 'Organic Waste']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select Bin Type',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a bin type';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.0),

              // Nickname field
              TextFormField(
                decoration: InputDecoration(labelText: 'Bin Nickname'),
                onSaved: (value) {
                  _nickname = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a nickname for the bin';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.0),

              // Weight field
              TextFormField(
                decoration: InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _weight = double.tryParse(value!) ?? 0.0;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the weight of the bin';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.0),

              // Description field (optional)
              TextFormField(
                decoration: InputDecoration(labelText: 'Description (optional)'),
                onSaved: (value) {
                  _description = value ?? '';
                },
              ),

              SizedBox(height: 16.0),

              // Image picker
              ElevatedButton(
                onPressed: _selectImage,
                child: Text('Select Bin Image'),
              ),
              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    )
                  : SizedBox.shrink(),

              SizedBox(height: 16.0),

              // Submit button
              ElevatedButton(
                onPressed: _addBin,
                child: Text('Add Bin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
