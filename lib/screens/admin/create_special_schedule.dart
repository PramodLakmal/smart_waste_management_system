import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateSpecialSchedulePage extends StatefulWidget {
  final String requestId;
  final String city;
  final String scheduledDate;
  final String address;
  final List wasteTypes;

  CreateSpecialSchedulePage({
    required this.requestId,
    required this.city,
    required this.scheduledDate,
    required this.address,
    required this.wasteTypes,
  });

  @override
  _CreateSpecialSchedulePageState createState() => _CreateSpecialSchedulePageState();
}

class _CreateSpecialSchedulePageState extends State<CreateSpecialSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  String? _selectedCollector;  // To store the selected collector's name
  String? _selectedCollectorId;  // To store the selected collector's ID

  @override
  void initState() {
    super.initState();
    // Initially, waste collectors will be fetched from Firestore
    _fetchWasteCollectors();
  }

  // List of waste collectors to populate the dropdown
  List<Map<String, dynamic>> _wasteCollectors = [];

  // Function to fetch waste collectors from Firestore
  Future<void> _fetchWasteCollectors() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'wasteCollector')
        .get();

    setState(() {
      _wasteCollectors = snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'uid': doc['uid'],
        };
      }).toList();
    });
  }

  Future<void> _createSpecialSchedule() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  try {
    await FirebaseFirestore.instance.collection('specialschedule').add({
      'requestId': widget.requestId,
      'city': widget.city,
      'scheduledDate': widget.scheduledDate,
      'address': widget.address, // Ensure this line is correct
      'wasteTypes': widget.wasteTypes,
      'wasteCollector': _selectedCollector, // Save the selected collector's name
      'wasteCollectorId': _selectedCollectorId, // Save the selected collector's ID
      'status': 'schedule created',
      'createdAt': DateTime.now(),
    });

    // Update the status in the specialWasteRequests collection
    await FirebaseFirestore.instance
        .collection('specialWasteRequests')
        .doc(widget.requestId)
        .update({'status': 'schedule created'});

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schedule created successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back after schedule creation
    Navigator.pop(context);
  } catch (e) {
    // Show error message in case of failure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error creating schedule. Please try again.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text('Create Special Schedule',
        style: TextStyle(
                color: const Color.fromARGB(221, 255, 255, 255), fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.green[800],
        elevation: 5,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Request Information Section
                  _buildInfoCard('City', widget.city, Icons.location_city),
                  SizedBox(height: 12),
                  _buildInfoCard('Date', widget.scheduledDate, Icons.calendar_today),
                  SizedBox(height: 12),
                  _buildInfoCard('Address', widget.address, Icons.location_on),
                  
                  // Waste Types Section
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Waste Types',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24),
                          ...widget.wasteTypes.map((waste) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  waste['type'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${waste['weight']} kg',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ),

                  // Waste Collector Dropdown
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCollector,
                            hint: Text('Select Waste Collector'),
                            onChanged: (value) {
                              setState(() {
                                _selectedCollector = value;
                                _selectedCollectorId = _wasteCollectors
                                    .firstWhere((collector) => collector['name'] == value)['uid'];
                              });
                            },
                            items: _wasteCollectors.map((collector) {
                              return DropdownMenuItem<String>(
                                value: collector['name'],
                                child: Text(collector['name'] ?? ''),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a waste collector';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Waste Collector',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createSpecialSchedule,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Create Schedule',
                                style: TextStyle(fontSize: 16, color: const Color.fromARGB(221, 255, 255, 255), fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
