import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/special_waste_collection_schedule.dart';
import '../../models/special_schedule_model.dart';
import 'update_special_schedule_page.dart';

class SpecialScheduleDetailsPage extends StatelessWidget {
  final SpecialSchedule specialSchedule;

  const SpecialScheduleDetailsPage({super.key, required this.specialSchedule});

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
  }

  Future<void> _deleteSchedule(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('specialschedule')
          .doc(specialSchedule.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule deleted successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SpecialWasteCollectionSchedule(),
        ),
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
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Special Schedule Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.event,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Address', specialSchedule.address, Icons.home),
                      _buildDetailItem('City', specialSchedule.city, Icons.location_city),
                      _buildDetailItem('Waste Collector', specialSchedule.wasteCollector, Icons.person),
                      _buildDetailItem('Scheduled Date', formatDateTime(specialSchedule.scheduledDate), Icons.access_time),
                      _buildDetailItem('Status', specialSchedule.status, Icons.info),
                      SizedBox(height: 16),
                      Text(
                        'Waste Types:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      ...specialSchedule.wasteTypes.map((wasteType) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '${wasteType.type} - ${wasteType.weight} kg',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateSpecialSchedulePage(specialSchedule: specialSchedule),
                      ),
                    );
                  },
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Color(0xFF4CAF50),
                ),
                _buildActionButton(
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
                    if (confirmDelete == true) {
                      _deleteSchedule(context);
                    }
                  },
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF81C784), size: 28),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
