import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for formatting dates and times
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import '../../models/schedule_model.dart';
import 'create_schedule.dart'; // Import to navigate to the create schedule page for editing

class ScheduleDetailsPage extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailsPage({Key? key, required this.schedule}) : super(key: key);

  // Helper function to format date and time
  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
  }

  Future<void> _deleteSchedule(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(schedule.id)
          .delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete the schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSchedulePage(schedule: schedule),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              bool confirmDelete = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Schedule'),
                  content: Text('Are you sure you want to delete this schedule?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmDelete) {
                _deleteSchedule(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection Zone: ${schedule.collectionZone}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vehicle Number: ${schedule.vehicleNumber}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Waste Collector: ${schedule.wasteCollector}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Start Time: ${formatDateTime(schedule.startTime)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'End Time: ${formatDateTime(schedule.endTime)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Location: ${schedule.location}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
