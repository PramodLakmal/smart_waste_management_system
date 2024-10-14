import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class BinSummaryScreen extends StatefulWidget {
  const BinSummaryScreen({super.key});

  @override
  _WasteCollectionReportState createState() => _WasteCollectionReportState();
}

class _WasteCollectionReportState extends State<BinSummaryScreen> {
  Future<List<Map<String, dynamic>>> fetchCollectedWasteRequests() async {
    List<Map<String, dynamic>> collectedRequests = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('status', isEqualTo: 'completed')
          .get();

      for (var doc in querySnapshot.docs) {
        collectedRequests.add({
          'wasteCollector': doc['wasteCollector'],
          'bins': doc['bins'],
          'city': doc['city'],
          'startTime': doc['startTime'].toDate(),
          'endTime': doc['endTime'].toDate(),
          'userIds': doc['userIds'],
        });
      }
    } catch (e) {
      print('Error fetching collected waste requests: $e');
    }

    return collectedRequests;
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collected Waste Summary Report', style: TextStyle(color: Color(0xFF2E7D32))),
      ),
      body: FutureBuilder(
        future: fetchCollectedWasteRequests(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No collected waste requests found.',
                style: TextStyle(color: Color(0xFF2E7D32), fontSize: 18),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var request = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  color: Colors.grey[200],
                  child: ExpansionTile(
                    title: Text(
                      'Collection in ${request['city']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Collector: ${request['wasteCollector']}',
                      style: TextStyle(color: Color(0xFF4CAF50)),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Bins', request['bins'].join(', ')),
                            _buildInfoRow('Start Time', formatDateTime(request['startTime'])),
                            _buildInfoRow('End Time', formatDateTime(request['endTime'])),
                            _buildInfoRow('User IDs', request['userIds'].join(', ')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}