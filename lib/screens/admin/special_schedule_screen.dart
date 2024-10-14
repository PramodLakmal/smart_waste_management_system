import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'completed_speacial_schedules.dart';

class SpecialSchedulePage extends StatefulWidget {
  const SpecialSchedulePage({super.key});

  @override
  _SpecialSchedulePageState createState() => _SpecialSchedulePageState();
}

class _SpecialSchedulePageState extends State<SpecialSchedulePage> {
  String? selectedScheduleId;

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Please log in first",
            style: TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Special Schedules', style: TextStyle(color: Color(0xFF2E7D32))),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('specialschedule')
            .where('wasteCollectorId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No special schedules found.",
                style: TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
              ),
            );
          }

          final schedules = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    final scheduledDate = DateFormat('MMMM d, yyyy').format(DateTime.parse(schedule['scheduledDate']));
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      color: Colors.grey[200],
                      child: ExpansionTile(
                        title: Text(
                          'Schedule for $scheduledDate',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        subtitle: Text(
                          'Status: ${schedule['status']}',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                        leading: Radio<String>(
                          value: schedule.id,
                          groupValue: selectedScheduleId,
                          activeColor: Color(0xFF4CAF50),
                          onChanged: (String? value) {
                            setState(() {
                              selectedScheduleId = value;
                            });
                          },
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Waste Types:",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                                SizedBox(height: 8),
                                ...schedule['wasteTypes'].map<Widget>((waste) {
                                  return Padding(
                                    padding: EdgeInsets.only(left: 16, bottom: 4),
                                    child: Text(
                                      "${waste['type']}: ${waste['weight']} kg",
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              BottomAppBar(
                color: Colors.grey[200],
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: selectedScheduleId == null
                            ? null
                            : () async {
                                await _completeSchedule(selectedScheduleId!);
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Color(0xFF4CAF50),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text('Collect Waste'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CompletedSchedulesPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Color(0xFF81C784),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text('View Completed'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeSchedule(String scheduleId) async {
    try {
      // Fetch the selected schedule document
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('specialschedule')
          .doc(scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        throw Exception('Schedule not found.');
      }

      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      String collectorId = scheduleData['wasteCollectorId']; // Assuming this is the collector's ID
      List<dynamic> wasteTypes = scheduleData['wasteTypes'];

      // Process each waste type
      for (var waste in wasteTypes) {
        String wasteType = waste['type'];
        double wasteWeight = waste['weight'];

        // Save to the 'collectedSpecialWastes' collection
        await FirebaseFirestore.instance.collection('collectedSpecialWastes').add({
          'collectorId': collectorId,
          'uid': FirebaseAuth.instance.currentUser!.uid, // Current user's ID
          'name': scheduleData['name'], // Assuming you have a name field in schedule
          'wasteCollector': scheduleData['wasteCollector'], // Assuming this field exists
          'weight': wasteWeight,
          'type': wasteType,
          'collectedTime': FieldValue.serverTimestamp(), // Optional: Time when collected
        });
      }

      // Mark the schedule as completed
      await FirebaseFirestore.instance
          .collection('specialschedule')
          .doc(scheduleId)
          .update({'status': 'completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule marked as completed and waste data collected!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
