import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBinScreen extends StatefulWidget {
  @override
  _AddBinScreenState createState() => _AddBinScreenState();
}

class _AddBinScreenState extends State<AddBinScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedBinType = 'Electrical Waste';
  String _nickname = '';
  String _description = '';
  double _weight = 0.0;

  final List<Map<String, dynamic>> _binTypes = [
    {'type': 'Electrical Waste', 'icon': Icons.electrical_services},
    {'type': 'Plastic Waste', 'icon': Icons.local_drink},
    {'type': 'Organic Waste', 'icon': Icons.eco},
  ];

  Future<void> _addBin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      CollectionReference bins = FirebaseFirestore.instance.collection('bins');
      DocumentReference newBinRef = bins.doc();

      Map<String, dynamic> binData = {
        'userId': userId,
        'binId': newBinRef.id,
        'type': _selectedBinType,
        'nickname': _nickname,
        'description': _description,
        'weight': _weight,
        'imageUrl': null,
        'filledPercentage': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'confirmed': false,
        'collectionRequestSent': false
      };

      await newBinRef.set(binData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bin added successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Bin'),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBinTypeSelector(),
                        SizedBox(height: 24.0),
                        _buildInputCard(),
                        SizedBox(height: 24.0),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBinTypeSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Bin Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _binTypes.map((binType) {
                bool isSelected = _selectedBinType == binType['type'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedBinType = binType['type']),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF4CAF50) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? Color(0xFF4CAF50) : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          binType['icon'],
                          color: isSelected ? Colors.white : Color(0xFF4CAF50),
                        ),
                        SizedBox(width: 8),
                        Text(
                          binType['type'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(
              label: 'Bin Nickname',
              onSaved: (value) => _nickname = value!,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a nickname for the bin' : null,
            ),
            SizedBox(height: 16),
            _buildInputField(
              label: 'Weight (kg)',
              keyboardType: TextInputType.number,
              onSaved: (value) => _weight = double.tryParse(value!) ?? 0.0,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter the weight of the bin';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildInputField(
              label: 'Description (optional)',
              onSaved: (value) => _description = value ?? '',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF2E7D32)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2.0),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _addBin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2E7D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Add Bin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}