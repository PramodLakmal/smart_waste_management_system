import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditRequestScreen extends StatefulWidget {
  final String requestId;

  const EditRequestScreen({super.key, required this.requestId});

  @override
  _EditRequestScreenState createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? requestData;

  bool isElectricalWasteSelected = false;
  bool isOrganicWasteSelected = false;
  bool isPlasticWasteSelected = false;
  double electricalWasteWeight = 0.0;
  double organicWasteWeight = 0.0;
  double plasticWasteWeight = 0.0;
  DateTime? selectedDate;

  String address = '';
  String city = '';
  final List<String> cities = ['Malabe', 'Kaduwela'];

  @override
  void initState() {
    super.initState();
    _fetchRequestData();
  }

  Future<void> _fetchRequestData() async {
    DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection('specialWasteRequests')
        .doc(widget.requestId)
        .get();

    setState(() {
      requestData = requestDoc.data() as Map<String, dynamic>?;

      if (requestData != null) {
        var wasteTypes = requestData!['wasteTypes'];

        isElectricalWasteSelected = wasteTypes.any((waste) => waste['type'] == 'Electrical Waste');
        isOrganicWasteSelected = wasteTypes.any((waste) => waste['type'] == 'Organic Waste');
        isPlasticWasteSelected = wasteTypes.any((waste) => waste['type'] == 'Plastic Waste');

        electricalWasteWeight = (wasteTypes.firstWhere((waste) => waste['type'] == 'Electrical Waste', orElse: () => {'weight': 0})['weight'] ?? 0).toDouble();
        organicWasteWeight = (wasteTypes.firstWhere((waste) => waste['type'] == 'Organic Waste', orElse: () => {'weight': 0})['weight'] ?? 0).toDouble();
        plasticWasteWeight = (wasteTypes.firstWhere((waste) => waste['type'] == 'Plastic Waste', orElse: () => {'weight': 0})['weight'] ?? 0).toDouble();

        selectedDate = DateTime.parse(requestData!['scheduledDate']);
        address = requestData!['address'] ?? '';
        city = requestData!['city'] ?? '';
      }
    });
  }

  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;

    List<Map<String, dynamic>> updatedWasteTypes = [];

    if (isElectricalWasteSelected && electricalWasteWeight > 0) {
      updatedWasteTypes.add({'type': 'Electrical Waste', 'weight': electricalWasteWeight});
    } else if (isElectricalWasteSelected) {
      _showErrorSnackBar('Please enter a valid weight for electrical waste greater than zero.');
      return;
    }

    if (isOrganicWasteSelected && organicWasteWeight > 0) {
      updatedWasteTypes.add({'type': 'Organic Waste', 'weight': organicWasteWeight});
    } else if (isOrganicWasteSelected) {
      _showErrorSnackBar('Please enter a valid weight for organic waste greater than zero.');
      return;
    }

    if (isPlasticWasteSelected && plasticWasteWeight > 0) {
      updatedWasteTypes.add({'type': 'Plastic Waste', 'weight': plasticWasteWeight});
    } else if (isPlasticWasteSelected) {
      _showErrorSnackBar('Please enter a valid weight for plastic waste greater than zero.');
      return;
    }

    await FirebaseFirestore.instance.collection('specialWasteRequests').doc(widget.requestId).update({
      'wasteTypes': updatedWasteTypes,
      'scheduledDate': selectedDate!.toIso8601String(),
      'address': address,
      'city': city,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request updated successfully.')),
    );

    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Special Waste Request'),
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
                child: requestData == null
                    ? CircularProgressIndicator()
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCard('Select Waste Type(s)', _buildWasteTypeSelectionContent()),
                            SizedBox(height: 20),
                            _buildCard('Address', _buildAddressContent()),
                            SizedBox(height: 20),
                            _buildCard('Collection Time', _buildCollectionTimeContent()),
                            SizedBox(height: 20),
                            _buildUpdateButton(),
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
        if (isElectricalWasteSelected) _buildWeightInput('Electrical Waste', electricalWasteWeight, (value) {
          electricalWasteWeight = double.tryParse(value) ?? 0.0;
        }),
        _buildWasteTypeCheckbox('Organic Waste', isOrganicWasteSelected, (value) {
          setState(() => isOrganicWasteSelected = value!);
        }),
        if (isOrganicWasteSelected) _buildWeightInput('Organic Waste', organicWasteWeight, (value) {
          organicWasteWeight = double.tryParse(value) ?? 0.0;
        }),
        _buildWasteTypeCheckbox('Plastic Waste', isPlasticWasteSelected, (value) {
          setState(() => isPlasticWasteSelected = value!);
        }),
        if (isPlasticWasteSelected) _buildWeightInput('Plastic Waste', plasticWasteWeight, (value) {
          plasticWasteWeight = double.tryParse(value) ?? 0.0;
        }),
      ],
    );
  }

  Widget _buildAddressContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
          initialValue: address,
          onChanged: (value) => address = value,
          validator: (value) => value!.isEmpty ? 'Please enter a valid address' : null,
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
          value: city.isNotEmpty ? city : null,
          items: cities.map((String city) {
            return DropdownMenuItem<String>(value: city, child: Text(city));
          }).toList(),
          onChanged: (value) => setState(() => city = value!),
          validator: (value) => value == null ? 'Please select a city' : null,
        ),
      ],
    );
  }

  Widget _buildCollectionTimeContent() {
    return ListTile(
      title: Text('Select Date: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'Not selected'}'),
      trailing: Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) setState(() => selectedDate = pickedDate);
      },
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

  Widget _buildWeightInput(String wasteType, double initialValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Enter $wasteType Weight (kg)',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        initialValue: initialValue.toString(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0) {
            return 'Please enter a valid weight greater than zero.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUpdateButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _updateRequest,
        child: Text('Update Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}