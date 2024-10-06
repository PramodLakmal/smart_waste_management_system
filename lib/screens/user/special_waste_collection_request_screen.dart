import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class SpecialWasteRequestScreen extends StatefulWidget {
  @override
  _SpecialWasteRequestScreenState createState() => _SpecialWasteRequestScreenState();
}

class _SpecialWasteRequestScreenState extends State<SpecialWasteRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Waste types and weights
  bool isElectricalWasteSelected = false;
  bool isOrganicWasteSelected = false;
  bool isPlasticWasteSelected = false;
  double electricalWasteWeight = 0.0;
  double organicWasteWeight = 0.0;
  double plasticWasteWeight = 0.0;

  // Address fields
  bool useSavedAddress = true;
  String userAddress = '';
  String userCity = '';
  String newAddress = '';
  String newCity = '';

  // Date fields
  DateTime? selectedDate;
  bool isNowSelected = true;

  // Optional description
  String description = '';

  final List<String> cities = ['Malabe', 'Kaduwela']; // List of cities

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure at least one waste type and weight is selected
    if (!isElectricalWasteSelected && !isOrganicWasteSelected && !isPlasticWasteSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one waste type and enter its weight.')),
      );
      return;
    }

    // Prepare the list of waste types with their respective weights
    List<Map<String, dynamic>> wasteTypes = [];

    if (isElectricalWasteSelected) {
      wasteTypes.add({'type': 'Electrical Waste', 'weight': electricalWasteWeight});
    }

    if (isOrganicWasteSelected) {
      wasteTypes.add({'type': 'Organic Waste', 'weight': organicWasteWeight});
    }

    if (isPlasticWasteSelected) {
      wasteTypes.add({'type': 'Plastic Waste', 'weight': plasticWasteWeight});
    }

    // Use saved address or the newly entered address
    String selectedAddress = useSavedAddress ? userAddress : newAddress;
    String selectedCity = useSavedAddress ? userCity : newCity;

    // The date and time for request: use current time for 'Request Now', or the selected date
    DateTime requestTime = DateTime.now();
    DateTime scheduledDate = isNowSelected ? requestTime : selectedDate!;

    // Default status to "pending"
    String status = "pending";

    // Save the data to Firestore in the 'specialWasteRequests' collection
    await FirebaseFirestore.instance.collection('specialWasteRequests').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'address': selectedAddress,
      'city': selectedCity,
      'description': description,
      'requestTime': requestTime.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status,
      'wasteTypes': wasteTypes, // Array of waste types with their weights
    });

    // Show a success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Special waste collection request submitted successfully.')),
    );

    Navigator.pop(context); // Return to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Special Waste Collection Request'),
      ),
      body: Padding(
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
                  onChanged: (value) {
                    electricalWasteWeight = double.tryParse(value) ?? 0.0;
                  },
                  validator: (value) {
                    if (isElectricalWasteSelected && (value == null || value.isEmpty || double.tryParse(value) == null)) {
                      return 'Please enter a valid weight for electrical waste.';
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
                  onChanged: (value) {
                    organicWasteWeight = double.tryParse(value) ?? 0.0;
                  },
                  validator: (value) {
                    if (isOrganicWasteSelected && (value == null || value.isEmpty || double.tryParse(value) == null)) {
                      return 'Please enter a valid weight for organic waste.';
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
                  onChanged: (value) {
                    plasticWasteWeight = double.tryParse(value) ?? 0.0;
                  },
                  validator: (value) {
                    if (isPlasticWasteSelected && (value == null || value.isEmpty || double.tryParse(value) == null)) {
                      return 'Please enter a valid weight for plastic waste.';
                    }
                    return null;
                  },
                ),
              SizedBox(height: 20),
              Text('Select Address:', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<bool>(
                title: Text('Use Saved Address: $userAddress, $userCity'),
                value: true,
                groupValue: useSavedAddress,
                onChanged: (value) {
                  setState(() {
                    useSavedAddress = value ?? true;
                  });
                },
              ),
              RadioListTile<bool>(
                title: Text('Enter Address Manually'),
                value: false,
                groupValue: useSavedAddress,
                onChanged: (value) {
                  setState(() {
                    useSavedAddress = value ?? false;
                  });
                },
              ),
              if (!useSavedAddress)
                Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Enter Address'),
                      onChanged: (value) {
                        newAddress = value;
                      },
                      validator: (value) {
                        if (!useSavedAddress && (value == null || value.isEmpty)) {
                          return 'Please enter a valid address.';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Select City'),
                      value: newCity.isNotEmpty ? newCity : null, // Set initial value
                      items: cities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          newCity = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (!useSavedAddress && (value == null || value.isEmpty)) {
                          return 'Please select a valid city.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              SizedBox(height: 20),
              Text('Select Collection Time:', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<bool>(
                title: Text('Request Now'),
                value: true,
                groupValue: isNowSelected,
                onChanged: (value) {
                  setState(() {
                    isNowSelected = value ?? true;
                  });
                },
              ),
              RadioListTile<bool>(
                title: Text('Schedule for Later'),
                value: false,
                groupValue: isNowSelected,
                onChanged: (value) {
                  setState(() {
                    isNowSelected = value ?? false;
                  });
                },
              ),
              if (!isNowSelected)
                ListTile(
                  title: Text('Select Date: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'Not selected'}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
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
              TextFormField(
                decoration: InputDecoration(labelText: 'Add Description (Optional)'),
                onChanged: (value) {
                  description = value;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                child: Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
