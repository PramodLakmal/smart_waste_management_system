import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SpecialWasteRequestScreen extends StatefulWidget {
  const SpecialWasteRequestScreen({super.key});

  @override
  _SpecialWasteRequestScreenState createState() => _SpecialWasteRequestScreenState();
}

class _SpecialWasteRequestScreenState extends State<SpecialWasteRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isElectricalWasteSelected = false;
  bool isOrganicWasteSelected = false;
  bool isPlasticWasteSelected = false;
  double electricalWasteWeight = 0.0;
  double organicWasteWeight = 0.0;
  double plasticWasteWeight = 0.0;

  bool useSavedAddress = true;
  String userAddress = '';
  String userCity = '';
  String newAddress = '';
  String newCity = '';

  DateTime? selectedDate;
  bool isNowSelected = true;

  String description = '';

  final List<String> cities = ['Malabe', 'Kaduwela'];

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      setState(() {
        userAddress = userDoc['address'] ?? '';
        userCity = userDoc['city'] ?? '';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isElectricalWasteSelected && !isOrganicWasteSelected && !isPlasticWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one waste type and enter its weight.')),
      );
      return;
    }

    List<Map<String, dynamic>> wasteTypes = [];
    if (isElectricalWasteSelected) wasteTypes.add({'type': 'Electrical Waste', 'weight': electricalWasteWeight});
    if (isOrganicWasteSelected) wasteTypes.add({'type': 'Organic Waste', 'weight': organicWasteWeight});
    if (isPlasticWasteSelected) wasteTypes.add({'type': 'Plastic Waste', 'weight': plasticWasteWeight});

    String selectedAddress = useSavedAddress ? userAddress : newAddress;
    String selectedCity = useSavedAddress ? userCity : newCity;

    DateTime requestTime = DateTime.now();
    DateTime scheduledDate = isNowSelected ? requestTime : selectedDate!;

    await FirebaseFirestore.instance.collection('specialWasteRequests').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'address': selectedAddress,
      'city': selectedCity,
      'description': description,
      'requestTime': requestTime.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': 'pending',
      'wasteTypes': wasteTypes,
      'paymentStatus': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Special waste collection request submitted successfully.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Special Waste Collection'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C784), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCard('Select Waste Type(s)', _buildWasteTypeSelectionContent()),
                      SizedBox(height: 20),
                      _buildCard('Address', _buildAddressSelectionContent()),
                      SizedBox(height: 20),
                      _buildCard('Collection Time', _buildCollectionTimeContent()),
                      SizedBox(height: 20),
                      _buildCard('Description', _buildDescriptionContent()),
                      SizedBox(height: 20),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTypeSelectionContent() {
    return Column(
      children: [
        _buildWasteTypeCheckbox('Electrical Waste', isElectricalWasteSelected, (value) {
          setState(() => isElectricalWasteSelected = value!);
        }),
        if (isElectricalWasteSelected) _buildWeightInput('Electrical Waste', (value) {
          electricalWasteWeight = double.tryParse(value) ?? 0.0;
        }),
        _buildWasteTypeCheckbox('Organic Waste', isOrganicWasteSelected, (value) {
          setState(() => isOrganicWasteSelected = value!);
        }),
        if (isOrganicWasteSelected) _buildWeightInput('Organic Waste', (value) {
          organicWasteWeight = double.tryParse(value) ?? 0.0;
        }),
        _buildWasteTypeCheckbox('Plastic Waste', isPlasticWasteSelected, (value) {
          setState(() => isPlasticWasteSelected = value!);
        }),
        if (isPlasticWasteSelected) _buildWeightInput('Plastic Waste', (value) {
          plasticWasteWeight = double.tryParse(value) ?? 0.0;
        }),
      ],
    );
  }

  Widget _buildAddressSelectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<bool>(
          title: Text('Use Saved Address'),
          subtitle: Text('$userAddress, $userCity'),
          value: true,
          groupValue: useSavedAddress,
          onChanged: (value) => setState(() => useSavedAddress = value!),
          activeColor: Color(0xFF4CAF50),
        ),
        RadioListTile<bool>(
          title: Text('Enter Address Manually'),
          value: false,
          groupValue: useSavedAddress,
          onChanged: (value) => setState(() => useSavedAddress = value!),
          activeColor: Color(0xFF4CAF50),
        ),
        if (!useSavedAddress) ...[
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => newAddress = value,
            validator: (value) => value!.isEmpty ? 'Please enter a valid address' : null,
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            value: newCity.isNotEmpty ? newCity : null,
            items: cities.map((String city) {
              return DropdownMenuItem<String>(value: city, child: Text(city));
            }).toList(),
            onChanged: (value) => setState(() => newCity = value!),
            validator: (value) => value == null ? 'Please select a city' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildCollectionTimeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<bool>(
          title: Text('Request Now'),
          value: true,
          groupValue: isNowSelected,
          onChanged: (value) => setState(() => isNowSelected = value!),
          activeColor: Color(0xFF4CAF50),
        ),
        RadioListTile<bool>(
          title: Text('Schedule for Later'),
          value: false,
          groupValue: isNowSelected,
          onChanged: (value) => setState(() => isNowSelected = value!),
          activeColor: Color(0xFF4CAF50),
        ),
        if (!isNowSelected)
          ListTile(
            title: Text('Select Date: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'Not selected'}'),
            trailing: Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) setState(() => selectedDate = pickedDate);
            },
          ),
      ],
    );
  }

  Widget _buildDescriptionContent() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: (value) => description = value,
    );
  }

  Widget _buildWasteTypeCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Color(0xFF4CAF50),
    );
  }

  Widget _buildWeightInput(String wasteType, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Enter $wasteType Weight (kg)',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty || double.tryParse(value) == null) {
            return 'Please enter a valid weight';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _submitRequest,
        child: Text('Submit Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}