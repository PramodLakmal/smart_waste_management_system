import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/waste_record_model.dart';
import '../../models/bin_model.dart'; // Import the Bin model
import '../../services/waste_service.dart';
import '../../services/bin_service.dart'; // Import the Bin service

class WasteDetailsScreen extends StatefulWidget {
  final String wasteCollector;

  const WasteDetailsScreen({super.key, required this.wasteCollector});

  @override
  _WasteDetailsScreenState createState() => _WasteDetailsScreenState();
}

class _WasteDetailsScreenState extends State<WasteDetailsScreen> {
  List<WasteRecord> _wasteRecords = [];
  List<Bin> _bins = []; // Add a list to hold bin details
  bool _isLoading = true;
  final WasteService _wasteService = WasteService();
  final BinService _binService = BinService(); // Create an instance of the BinService

  final TextEditingController _weightController = TextEditingController();
  String? _selectedWasteType;
  String? _selectedStatus;
  String _currentLocation = 'Unknown';

  @override
  void initState() {
    super.initState();
    _fetchWasteRecords();
    _fetchBinDetails(); // Fetch bin details
    _getCurrentLocation();
  }

  Future<void> _fetchWasteRecords() async {
    setState(() => _isLoading = true);
    try {
      _wasteRecords = await _wasteService.fetchWasteRecordsByCollector(widget.wasteCollector);
    } catch (e) {
      print("Error fetching waste records: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBinDetails() async {
    setState(() => _isLoading = true);
    try {
      // Fetch bin details based on the waste collector
      _bins = (await _binService.getBinsForCollector(widget.wasteCollector)) as List<Bin>;
    } catch (e) {
      print("Error fetching bin details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWasteRecord() async {
    final String wasteType = _selectedWasteType ?? '';
    final double weight = double.tryParse(_weightController.text) ?? 0.0;

    if (wasteType.isEmpty || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter valid waste type and weight')));
      return;
    }

    try {
      await _wasteService.addWasteRecord(
        WasteRecord(
          id: '',
          wasteType: wasteType,
          weight: weight,
          wasteCollector: widget.wasteCollector,
          status: _selectedStatus ?? 'Collected',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waste record added successfully')));
      _selectedWasteType = null;
      _weightController.clear();
      _fetchWasteRecords();
    } catch (e) {
      print("Error adding waste record: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding waste record')));
    }
  }

  Future<void> _updateWasteStatus(String id) async {
    final String status = _selectedStatus ?? '';
    if (status.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a status')));
      return;
    }

    try {
      await _wasteService.updateWasteStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waste status updated to $status')));
      _fetchWasteRecords(); // Refresh the list of records
    } catch (e) {
      print("Error updating waste status: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating waste status')));
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _currentLocation = 'Failed to get location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Details for ${widget.wasteCollector}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Current Location: $_currentLocation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Select Waste Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedWasteType,
                    hint: Text('Choose waste type'),
                    items: <String>['Organic', 'Inorganic'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedWasteType = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addWasteRecord,
                    child: Text('Add Waste Record'),
                  ),
                  SizedBox(height: 20),
                  Divider(height: 20, thickness: 2),
                  
                  // Display Bin Details
                  Text(
                    'Bins for ${widget.wasteCollector}:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: _bins.isEmpty
                        ? Center(child: Text('No bins found.'))
                        : ListView.builder(
                            itemCount: _bins.length,
                            itemBuilder: (context, index) {
                              final bin = _bins[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text('Bin ID: ${bin.id}'),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  Divider(height: 20, thickness: 2),
                  
                  Expanded(
                    child: _wasteRecords.isEmpty
                        ? Center(child: Text('No waste records found.'))
                        : ListView.builder(
                            itemCount: _wasteRecords.length,
                            itemBuilder: (context, index) {
                              final record = _wasteRecords[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text('Waste Type: ${record.wasteType}'),
                                  subtitle: Text('Weight: ${record.weight} kg\nStatus: ${'Collected'}'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}