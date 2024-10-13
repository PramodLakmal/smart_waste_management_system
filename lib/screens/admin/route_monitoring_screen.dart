import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'bin_summary_screen.dart';

class BinIdsScreen extends StatefulWidget {
  final List<dynamic> binIds;
  final String wasteCollector;

  BinIdsScreen({required this.binIds, required this.wasteCollector});

  @override
  _BinIdsScreenState createState() => _BinIdsScreenState();
}

class _BinIdsScreenState extends State<BinIdsScreen> {
  List<String> binIdsRemaining = [];
  List<String> collectedBins = [];

  @override
  void initState() {
    super.initState();
    binIdsRemaining = List<String>.from(widget.binIds); // Copy the bin IDs to a mutable list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collect Bins - ${widget.wasteCollector}'),
      ),
      body: binIdsRemaining.isEmpty
          ? Center(child: Text('All bins have been collected!'))
          : ListView.builder(
              itemCount: binIdsRemaining.length,
              itemBuilder: (context, index) {
                String binId = binIdsRemaining[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text('Bin ID: $binId'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        collectBin(binId);
                      },
                      child: Text('Collect'),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: collectedBins.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BinSummaryScreen(collectedBins: collectedBins, collectedBinIds: [],),
                    ),
                  );
                }
              : null, // Disable button if no bins are collected
          child: Text('View Summary Report'),
        ),
      ),
    );
  }

  // Function to collect a bin and update Firestore
  Future<void> collectBin(String binId) async {
    try {
      // Step 1: Update the 'bins' collection
      await FirebaseFirestore.instance.collection('bins').doc(binId).update({
        'filledPercentage': 0, // Set filledPercentage to 0
      });

      // Step 2: Update the 'wasteCollectionRequests' collection
      QuerySnapshot wasteRequestSnapshot = await FirebaseFirestore.instance
          .collection('wasteCollectionRequests')
          .where('binId', isEqualTo: binId)
          .get();

      if (wasteRequestSnapshot.docs.isNotEmpty) {
        DocumentSnapshot wasteRequestDoc = wasteRequestSnapshot.docs.first;
        await FirebaseFirestore.instance
            .collection('wasteCollectionRequests')
            .doc(wasteRequestDoc.id)
            .update({
          'isCollected': true, // Mark as collected
        });
      }

      // Step 3: Update the UI - remove bin from list and add to collectedBins
      setState(() {
        binIdsRemaining.remove(binId); // Remove from remaining bins list
        collectedBins.add(binId); // Add to collected bins list
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bin $binId collected successfully!')));

    } catch (e) {
      print('Error collecting bin: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to collect bin')));
    }
  }
}
