import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'completed_speacial_schedules.dart'; // Import the new page

class SpecialSchedulePage extends StatefulWidget {
  @override
  _SpecialSchedulePageState createState() => _SpecialSchedulePageState();
}

class _SpecialSchedulePageState extends State<SpecialSchedulePage> {
  String? selectedScheduleId; // To store the selected schedule ID

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Center(child: Text("Please log in first"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Special Schedules'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('specialschedule')
            .where('wasteCollectorId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No special schedules found."));
          }

          final schedules = snapshot.data!.docs;

          return Column(
            children: [
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
                      leading: Radio<String>(
                        value: schedule.id,
                        groupValue: selectedScheduleId,
                        onChanged: (String? value) {
                          setState(() {
                            selectedScheduleId = value;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: selectedScheduleId == null
                          ? null // Disable button if no schedule is selected
                          : () async {
                              await _completeSchedule(selectedScheduleId!);
                            },
                      child: Text('Collect Waste'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CompletedSchedulesPage()),
                        );
                      },
                      child: Text('View Completed Schedules'),
                    ),
                  ],
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
      // Update the schedule status to "completed"
      await FirebaseFirestore.instance
          .collection('specialschedule')
          .doc(scheduleId)
          .update({'status': 'completed'});

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule marked as completed!')),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing schedule: $e')),
      );
    }
  }
}
