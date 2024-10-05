import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/waste_record_model.dart';
import '../../services/waste_service.dart';

class WasteDetailsScreen extends StatefulWidget {
  final String wasteCollector;

  const WasteDetailsScreen({super.key, required this.wasteCollector});

  @override
  _WasteDetailsScreenState createState() => _WasteDetailsScreenState();
}

class _WasteDetailsScreenState extends State<WasteDetailsScreen> {
  List<WasteRecord> _wasteRecords = [];
  bool _isLoading = true;
  final WasteService _wasteService = WasteService();

  // Controllers for weight input field
  final TextEditingController _weightController = TextEditingController();
  
  // Variable to hold the selected waste type
  String? _selectedWasteType;

  @override
  void initState() {
    super.initState();
    _fetchWasteRecords(); // Fetch waste records when the screen is initialized
  }

  Future<void> _fetchWasteRecords() async {
    try {
      _wasteRecords = await _wasteService.fetchWasteRecordsByCollector(widget.wasteCollector);
      setState(() {
        _isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      print("Error fetching waste records: $e");
      setState(() {
        _isLoading = false; // Stop loading if there's an error
      });
    }
  }

  Future<void> _addWasteRecord() async {
    final String wasteType = _selectedWasteType ?? '';
    final double weight = double.tryParse(_weightController.text) ?? 0.0;

    if (wasteType.isEmpty || weight <= 0) {
      // Basic validation for inputs
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter valid waste type and weight')));
      return;
    }

    try {
      await _wasteService.addWasteRecord(
        WasteRecord(
          id: '', // Firestore will generate an ID
          wasteType: wasteType,
          weight: weight,
          wasteCollector: widget.wasteCollector,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waste record added successfully')));
      
      // Clear the form
      _selectedWasteType = null; // Reset the selected waste type
      _weightController.clear();
      
      // Refresh the list of records
      _fetchWasteRecords();
    } catch (e) {
      print("Error adding waste record: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding waste record')));
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
                  // Dropdown for Waste Type
                  Text(
                    'Select Waste Type:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _selectedWasteType,
                    hint: Text('Choose waste type'),
                    items: <String>['Organic', 'Inorganic']
                        .map<DropdownMenuItem<String>>((String value) {
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
                  
                  // Input form for weight
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
                  
                  // Divider to separate the form from the list
                  Divider(height: 20, thickness: 2),

                  // List of waste records
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
                                  subtitle: Text('Weight: ${record.weight} kg\n'),
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
