import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WasteSummaryScreen extends StatelessWidget {
  final String routeId;

  const WasteSummaryScreen({
    Key? key,
    required this.routeId, required List<Object> schedules,
  }) : super(key: key);

  // Fetch waste entries from Firestore for the specified route
  Future<List<Map<String, dynamic>>> _fetchWasteEntries() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('waste_entries')
        .where('routeId', isEqualTo: routeId)
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Group waste entries by waste collector and date
  Map<String, Map<String, double>> _groupWasteByCollectorAndDate(List<Map<String, dynamic>> wasteEntries) {
    Map<String, Map<String, double>> groupedData = {};

    for (var entry in wasteEntries) {
      String collector = entry['wasteCollector'] ?? 'Unknown';
      Timestamp timestamp = entry['timestamp'] ?? Timestamp.now();
      DateTime date = timestamp.toDate();
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      double weight = (entry['wasteWeight'] ?? 0.0) as double;

      // Initialize the group if not present
      if (!groupedData.containsKey(collector)) {
        groupedData[collector] = {};
      }

      // Initialize the date if not present
      if (!groupedData[collector]!.containsKey(formattedDate)) {
        groupedData[collector]![formattedDate] = 0.0;
      }

      // Sum up the waste weight
      groupedData[collector]![formattedDate] = groupedData[collector]![formattedDate]! + weight;
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Collection Summary - Route: $routeId'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWasteEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching data: ${snapshot.error}'));
          }

          final wasteEntries = snapshot.data ?? [];

          if (wasteEntries.isEmpty) {
            return Center(child: Text('No waste entries found for this route.'));
          }

          // Group waste entries by collector and date
          Map<String, Map<String, double>> groupedData = _groupWasteByCollectorAndDate(wasteEntries);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: groupedData.entries.map((collectorEntry) {
                String collector = collectorEntry.key;
                Map<String, double> dateEntries = collectorEntry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ExpansionTile(
                    title: Text('Collector: $collector'),
                    children: dateEntries.entries.map((dateEntry) {
                      String date = dateEntry.key;
                      double totalWeight = dateEntry.value;

                      return ListTile(
                        title: Text('Date: $date'),
                        subtitle: Text('Total Waste Collected: ${totalWeight.toStringAsFixed(2)} kg'),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
