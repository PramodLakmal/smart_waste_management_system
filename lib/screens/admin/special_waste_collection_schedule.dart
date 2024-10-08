import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/screens/admin/special_schedule_details.dart';
import 'package:smart_waste_management_system/screens/admin/create_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/create_special_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/special_requests_for_scheduling.dart';
import 'package:smart_waste_management_system/screens/admin/waste_collection_schedule.dart';
import 'package:smart_waste_management_system/screens/home_screen.dart';
import '../../models/special_schedule_model.dart';

class SpecialWasteCollectionSchedule extends StatelessWidget {
  const SpecialWasteCollectionSchedule({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Waste Collection Schedule'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              backgroundColor: Colors.purple[100],
              child: Text('A'),
            ),
          ),
        ],
      ),
      drawer: Sidebar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('specialschedule').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Special Schedules found.'));
          }

          List<SpecialSchedule> schedules = snapshot.data!.docs.map((doc) {
            return SpecialSchedule.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              SpecialSchedule schedule = schedules[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: ListTile(
                  title: Text('Schedule: ${schedule.address}, ${schedule.city}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request ID: ${schedule.requestId}'),
                      Text('Scheduled Date: ${schedule.scheduledDate.toLocal()}'),
                      Text('Status: ${schedule.status}'),
                      Text('Vehicle Number: ${schedule.vehicleNumber}'),
                      Text('Waste Collector: ${schedule.wasteCollector}'),
                      const SizedBox(height: 8),
                      Text('Waste Types:'),
                      for (var waste in schedule.wasteTypes)
                        Text('Type: ${waste.type}, Weight: ${waste.weight}kg'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SpecialScheduleDetailsPage(specialSchedule: schedule,)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 73, 204, 255),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Waste Collection Schedule'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WasteCollectionSchedule()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Special Requests'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SpecialRequestsForSchedulingScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Special Schedules'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SpecialWasteCollectionSchedule()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              // Navigate to Settings Page
            },
          ),
        ],
      ),
    );
  }
}