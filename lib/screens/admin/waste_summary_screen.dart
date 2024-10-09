import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // Add this for grouping
import 'package:intl/intl.dart'; // Add this for date formatting

class WasteSummaryScreen extends StatelessWidget {
  final String routeId;

  WasteSummaryScreen({required this.routeId, required List<Object> schedules});

  // Fetch waste summary along with collector details and vehicle number
  Future<List<Map<String, dynamic>>> _fetchWasteSummary() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('waste_entries')
        .where('routeId', isEqualTo: routeId)
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Summary', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWasteSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading waste summary'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No waste data found for this route.'));
          }

          final wasteEntries = snapshot.data!;

          // Group waste entries by collector name and collected date
          final groupedEntries = groupBy(
            wasteEntries,
            (Map<String, dynamic> entry) => entry['wasteCollector'],
          );

          final Map<String, Map<String, List<Map<String, dynamic>>>> finalGrouping = {};

          groupedEntries.forEach((collector, entries) {
            // Group by date within each collector
            final groupedByDate = groupBy(entries, (Map<String, dynamic> entry) {
              final date = (entry['timestamp'] as Timestamp).toDate(); // Assuming collectedDate is a Timestamp
              return DateFormat('yyyy-MM-dd').format(date); // Format date as needed
            });

            finalGrouping[collector] = groupedByDate;
          });

          return ListView.builder(
            itemCount: finalGrouping.keys.length,
            itemBuilder: (context, index) {
              final collectorName = finalGrouping.keys.elementAt(index);
              final groupedByDate = finalGrouping[collectorName]!;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waste Collector: $collectorName',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      // List each date for this collector
                      for (var date in groupedByDate.keys) ...[
                        Text(
                          'Collected Date: $date',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        // List each entry for this date
                        for (var entry in groupedByDate[date]!) ...[
                          Text(
                            'Vehicle Number: ${entry['vehicleNumber']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Waste Type: ${entry['wasteType']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Waste Weight: ${entry['wasteWeight']} kg',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
