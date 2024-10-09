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
  final TextEditingController _collectorController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _createSpecialSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('specialschedule').add({
        'requestId': widget.requestId,
        'city': widget.city,
        'scheduledDate': widget.scheduledDate,
        'address': widget.address,
        'wasteTypes': widget.wasteTypes,
        'wasteCollector': _collectorController.text,
        'vehicleNumber': _vehicleController.text,
        'status': 'schedule created',
        'createdAt': DateTime.now(),
      });

      await FirebaseFirestore.instance
          .collection('specialWasteRequests')
          .doc(widget.requestId)
          .update({'status': 'schedule created'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule created successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
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
      appBar: AppBar(
        title: Text('Create Special Schedule'),
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
                              Icon(Icons.delete_outline, color: Colors.blue),
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

                  // Input Fields
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _collectorController,
                            decoration: InputDecoration(
                              labelText: 'Waste Collector',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter waste collector name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _vehicleController,
                            decoration: InputDecoration(
                              labelText: 'Vehicle Number',
                              prefixIcon: Icon(Icons.local_shipping),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter vehicle number';
                              }
                              return null;
                            },
                          ),
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
                              Icon(Icons.schedule),
                              SizedBox(width: 8),
                              Text(
                                'Create Schedule',
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