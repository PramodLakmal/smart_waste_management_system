import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletedSchedulesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Center(child: Text("Please log in first"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Completed Special Schedules'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('specialschedule')
            .where('wasteCollectorId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No completed schedules found."));
          }

          final schedules = snapshot.data!.docs;
          double totalWasteCollected = 0.0;

          // Calculate total waste collected
          for (var schedule in schedules) {
            for (var waste in schedule['wasteTypes']) {
              totalWasteCollected += (waste['weight'] as num).toDouble();
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Total Waste Collected: ${totalWasteCollected.toStringAsFixed(2)} kg",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Scheduled Date: ${schedule['scheduledDate']}"),
                          Text("Status: ${schedule['status']}"),
                          Text("Waste Types:"),
                          ...schedule['wasteTypes'].map<Widget>((waste) {
                            return Text("${waste['type']}: ${waste['weight']} kg");
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
