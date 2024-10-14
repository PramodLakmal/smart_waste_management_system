import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/special_schedule_details.dart';
import 'package:smart_waste_management_system/screens/admin/special_requests_for_scheduling.dart';
import 'package:smart_waste_management_system/screens/admin/waste_collection_schedule.dart';
import 'package:smart_waste_management_system/screens/home_screen.dart';
import '../../models/special_schedule_model.dart';

class SpecialWasteCollectionSchedule extends StatelessWidget {
  const SpecialWasteCollectionSchedule({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      drawer: Sidebar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('specialschedule').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_outlined, size: 64, color: const Color.fromARGB(255, 0, 0, 0)),
                  SizedBox(height: 16),
                  Text(
                    'No Special Schedules Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          List<SpecialSchedule> schedules = snapshot.data!.docs
              .map((doc) => SpecialSchedule.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              return _buildScheduleCard(context, schedules[index]);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green[800],
      elevation: 0,
      title: Text(
        'Special Waste Collection',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.grey[700]),
          onPressed: () {},
        ),
        IconButton(
          icon: Badge(
            label: Text('2'),
            child: Icon(Icons.notifications_none, color: Colors.grey[700]),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: Colors.grey[700]),
          onPressed: () {},
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CircleAvatar(
            backgroundColor: Colors.green[700],
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(BuildContext context, SpecialSchedule schedule) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.green[100],
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpecialScheduleDetailsPage(
                specialSchedule: schedule,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusIndicator(schedule.status),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.address,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          schedule.city,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Scheduled Date',
                DateFormat('MMM dd, yyyy HH:mm').format(schedule.scheduledDate.toLocal()),
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                Icons.person,
                'Collector',
                schedule.wasteCollector,
              ),
              SizedBox(height: 16),
              _buildWasteTypesSection(schedule.wasteTypes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.red;
        break;
      case 'schedule created':
        statusColor = const Color.fromARGB(255, 15, 122, 19);
        break;
      case 'in progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[800]),
        SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWasteTypesSection(List<dynamic> wasteTypes) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[500],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waste Types',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wasteTypes.map((waste) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '${waste.type}: ${waste.weight}kg',
                  style: TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green[700],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          'S',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Scheduling',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.home,
            'Home',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.schedule,
            'Waste Collection Schedule',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WasteCollectionSchedule()),
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.list_alt,
            'Special Requests',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SpecialRequestsForSchedulingScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.calendar_today,
            'Special Schedules',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SpecialWasteCollectionSchedule(),
              ),
            ),
            isSelected: true,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
    bool showTrailing = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green[700] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green[700] : Colors.grey[900],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: showTrailing ? Icon(Icons.chevron_right) : null,
      selected: isSelected,
      selectedTileColor: Colors.green[50],
      onTap: onTap,
    );
  }
}