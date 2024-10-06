import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class EditRequestScreen extends StatefulWidget {
  final String requestId;

  EditRequestScreen({required this.requestId});

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
  
  // New fields for address and city
  String address = '';
  String city = '';

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
      // Initialize fields based on the request data
      var wasteTypes = requestData!['wasteTypes'];

      isElectricalWasteSelected = wasteTypes.any((waste) => waste['type'] == 'Electrical Waste');
      isOrganicWasteSelected = wasteTypes.any((waste) => waste['type'] == 'Organic Waste');
      isPlasticWasteSelected = wasteTypes.any((waste) => waste['type'] == 'Plastic Waste');

      electricalWasteWeight = (wasteTypes.firstWhere((waste) => waste['type'] == 'Electrical Waste', orElse: () => {'weight': 0})['weight'] ?? 0).toDouble();
      organicWasteWeight = (wasteTypes.firstWhere((waste) => waste['type'] == 'Organic Waste', orElse: () => {'weight': 0})['weight'] ?? 0).toDouble();
      plasticWasteWeight = (wasteTypes.firstWhere((waste) => waste['type'] == 'Plastic Waste', orElse: () => {'weight': 0})['weight'] ?? 0).toDouble();

      selectedDate = DateTime.parse(requestData!['scheduledDate']);

      // Initialize address and city
      address = requestData!['address'] ?? '';
      city = requestData!['city'] ?? '';
    }
  });
}


  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;

    List<Map<String, dynamic>> updatedWasteTypes = [];

    // Check for weights greater than zero
    if (isElectricalWasteSelected && electricalWasteWeight > 0) {
      updatedWasteTypes.add({'type': 'Electrical Waste', 'weight': electricalWasteWeight});
    } else if (isElectricalWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid weight for electrical waste greater than zero.')),
      );
      return;
    }

    if (isOrganicWasteSelected && organicWasteWeight > 0) {
      updatedWasteTypes.add({'type': 'Organic Waste', 'weight': organicWasteWeight});
    } else if (isOrganicWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid weight for organic waste greater than zero.')),
      );
      return;
    }

    if (isPlasticWasteSelected && plasticWasteWeight > 0) {
      updatedWasteTypes.add({'type': 'Plastic Waste', 'weight': plasticWasteWeight});
    } else if (isPlasticWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid weight for plastic waste greater than zero.')),
      );
      return;
    }

    // Proceed to update Firestore if all weights are valid
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Special Waste Request'),
      ),
      body: requestData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('Select Waste Type(s) and Enter Weight:', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: Text('Electrical Waste'),
                      value: isElectricalWasteSelected,
                      onChanged: (value) {
                        setState(() {
                          isElectricalWasteSelected = value ?? false;
                        });
                      },
                    ),
                    if (isElectricalWasteSelected)
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Enter Electrical Waste Weight (kg)'),
                        keyboardType: TextInputType.number,
                        initialValue: electricalWasteWeight.toString(),
                        onChanged: (value) {
                          electricalWasteWeight = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) {
                          if (isElectricalWasteSelected && (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0)) {
                            return 'Please enter a valid weight for electrical waste greater than zero.';
                          }
                          return null;
                        },
                      ),
                    CheckboxListTile(
                      title: Text('Organic Waste'),
                      value: isOrganicWasteSelected,
                      onChanged: (value) {
                        setState(() {
                          isOrganicWasteSelected = value ?? false;
                        });
                      },
                    ),
                    if (isOrganicWasteSelected)
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Enter Organic Waste Weight (kg)'),
                        keyboardType: TextInputType.number,
                        initialValue: organicWasteWeight.toString(),
                        onChanged: (value) {
                          organicWasteWeight = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) {
                          if (isOrganicWasteSelected && (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0)) {
                            return 'Please enter a valid weight for organic waste greater than zero.';
                          }
                          return null;
                        },
                      ),
                    CheckboxListTile(
                      title: Text('Plastic Waste'),
                      value: isPlasticWasteSelected,
                      onChanged: (value) {
                        setState(() {
                          isPlasticWasteSelected = value ?? false;
                        });
                      },
                    ),
                    if (isPlasticWasteSelected)
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Enter Plastic Waste Weight (kg)'),
                        keyboardType: TextInputType.number,
                        initialValue: plasticWasteWeight.toString(),
                        onChanged: (value) {
                          plasticWasteWeight = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) {
                          if (isPlasticWasteSelected && (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0)) {
                            return 'Please enter a valid weight for plastic waste greater than zero.';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),
                    // New Fields for Address and City
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Address'),
                      initialValue: address,
                      onChanged: (value) {
                        address = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'City'),
                      initialValue: city,
                      onChanged: (value) {
                        city = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      title: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateRequest,
                      child: Text('Update Request'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
