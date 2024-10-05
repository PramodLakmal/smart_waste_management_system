import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io'; // For File type
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For image upload

class EditBinScreen extends StatefulWidget {
  final DocumentSnapshot binData; // Pass bin data from the profile screen

  EditBinScreen({required this.binData});

  @override
  _EditBinScreenState createState() => _EditBinScreenState();
}

class _EditBinScreenState extends State<EditBinScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedBinType = 'Electrical Waste';
  String _nickname = '';
  String _description = '';
  double _weight = 0.0;
  File? _imageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBinData(); // Load existing bin data
  }

  // Load existing bin data into the form
  void _loadBinData() {
    _nickname = widget.binData['nickname'];
    _selectedBinType = widget.binData['type'];
    _description = widget.binData['description'] ?? '';
    _weight = widget.binData['weight'].toDouble();
  }

  Future<void> _selectImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateBin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Reference to the bin document in Firestore
    DocumentReference binRef = FirebaseFirestore.instance.collection('bins').doc(widget.binData.id);

    // Upload the image to Firebase Storage if available
    String? imageUrl = widget.binData['imageUrl'];
    if (_imageFile != null) {
      String imagePath = 'bin_images/${binRef.id}.jpg';
      TaskSnapshot uploadTask = await FirebaseStorage.instance
          .ref(imagePath)
          .putFile(_imageFile!);
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    // Update the bin data
    await binRef.update({
      'nickname': _nickname,
      'type': _selectedBinType,
      'description': _description,
      'weight': _weight,
      'imageUrl': imageUrl,
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bin updated successfully!'),
    ));

    Navigator.pop(context); // Navigate back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Bin'),
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
                initialValue: _nickname,
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
                initialValue: _weight.toString(),
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
                initialValue: _description,
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
                  : widget.binData['imageUrl'] != null
                      ? Image.network(
                          widget.binData['imageUrl'],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        )
                      : SizedBox.shrink(),

              SizedBox(height: 16.0),

              // Submit button
              ElevatedButton(
                onPressed: _updateBin,
                child: Text('Update Bin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
