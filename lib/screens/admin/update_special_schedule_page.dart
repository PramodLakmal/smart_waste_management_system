import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for formatting dates and times
import '../../models/special_schedule_model.dart'; // Import your SpecialSchedule model

class UpdateSpecialSchedulePage extends StatefulWidget {
  final SpecialSchedule specialSchedule;

  const UpdateSpecialSchedulePage({Key? key, required this.specialSchedule})
      : super(key: key);

  @override
  _UpdateSpecialSchedulePageState createState() => _UpdateSpecialSchedulePageState();
}

class _UpdateSpecialSchedulePageState extends State<UpdateSpecialSchedulePage> {
  final TextEditingController _vehicleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _selectedCollector; // Store the selected collector's name
  String? _selectedCollectorId; // Store the selected collector's ID

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _selectedCollector = widget.specialSchedule.wasteCollector;
    _selectedCollectorId = widget.specialSchedule.wasteCollectorId;
    // Fetch the collectors
    _fetchWasteCollectors();
  }

  // List of waste collectors to populate the dropdown
  List<Map<String, dynamic>> _wasteCollectors = [];

  // Fetch waste collectors from Firestore
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

  // Update special schedule in Firestore
  Future<void> _updateSpecialSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('specialschedule')
          .doc(widget.specialSchedule.id)
          .update({
        'wasteCollector': _selectedCollector, // Save selected collector's name
        'wasteCollectorId': _selectedCollectorId, // Save selected collector's ID
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context); // Go back after successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating schedule: $e'),
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
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      appBar: AppBar(
        title: Text('Update Special Schedule'),
        elevation: 0,
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
                  _buildInfoCard('City', widget.specialSchedule.city, Icons.location_city),
                  SizedBox(height: 12),
                  _buildInfoCard('Date', DateFormat('yyyy-MM-dd').format(widget.specialSchedule.scheduledDate), Icons.calendar_today),
                  SizedBox(height: 12),
                  _buildInfoCard('Address', widget.specialSchedule.address, Icons.location_on),

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
                              Icon(Icons.delete_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Waste Types',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Divider(height: 24),
                          ...widget.specialSchedule.wasteTypes.map((waste) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  waste.type, // Updated from `waste['type']`
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${waste.weight} kg', // Updated from `waste['weight']`
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
                    onPressed: _isLoading ? null : _updateSpecialSchedule,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.update),
                              SizedBox(width: 8),
                              Text(
                                'Update Schedule',
                                style: TextStyle(fontSize: 16),
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
