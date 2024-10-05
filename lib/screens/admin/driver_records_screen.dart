import 'package:flutter/material.dart';
import '../../models/waste_record_model.dart';
import '../../services/waste_service.dart';
import 'waste_entry_screen.dart';

class DriverRecordsScreen extends StatefulWidget {
  final String routeId;
  final String driverId;

  const DriverRecordsScreen({super.key,  required this.driverId, required this.routeId});

  @override
  _DriverRecordsScreenState createState() => _DriverRecordsScreenState();
}

class _DriverRecordsScreenState extends State<DriverRecordsScreen> {
  final WasteService _wasteService = WasteService();
  bool _isLoading = true;
  List<WasteRecord> _wasteRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchWasteRecords();
  }

  Future<void> _fetchWasteRecords() async {
    List<WasteRecord> records = await _wasteService.getWasteRecordsByRoute(widget.routeId);
    setState(() {
      _wasteRecords = records;
      _isLoading = false;
    });
  }

  Future<void> _navigateToWasteEntry() async {
    // Navigate to WasteEntryScreen and await result
    WasteRecord? newRecord = await Navigator.push<WasteRecord>(
      context,
      MaterialPageRoute(
        builder: (context) => WasteEntryScreen(routeId: widget.routeId),
      ),
    );

    // If new record was added, update the waste records list
    if (newRecord != null) {
      setState(() {
        _wasteRecords.add(newRecord);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Collection Records'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _wasteRecords.isEmpty
              ? Center(child: Text('No records found.'))
              : ListView.builder(
                  itemCount: _wasteRecords.length,
                  itemBuilder: (context, index) {
                    WasteRecord record = _wasteRecords[index];
                    return Card(
                      child: ListTile(
                        title: Text('Waste Type: ${record.wasteType}'),
                        subtitle: Text('Weight: ${record.weight} kg | Status: ${record.status}'),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToWasteEntry,
        child: Icon(Icons.add),
      ),
    );
  }
}
