import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/create_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/create_special_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/special_requests_for_scheduling.dart';
import 'package:smart_waste_management_system/screens/admin/special_waste_collection_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/waste_collection_schedule.dart'; // Import WasteCollectionSchedule
import 'package:smart_waste_management_system/screens/home_screen.dart';
import '../../models/schedule_model.dart';

class SpecialRequestsForSchedulingScreen extends StatefulWidget {
  @override
  _SpecialRequestsForSchedulingScreenState createState() => _SpecialRequestsForSchedulingScreenState();
}

class _SpecialRequestsForSchedulingScreenState extends State<SpecialRequestsForSchedulingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Special Waste Collection Schedule'),
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
      drawer: Sidebar(), // Add sidebar here

      body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('specialWasteRequests').snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return Center(child: CircularProgressIndicator());
    }

    // Fetch all requests
    final requests = snapshot.data!.docs;

    // Sort requests so that pending ones come first
    requests.sort((a, b) {
      if (a['status'] == 'pending' && b['status'] != 'pending') {
        return -1; // `a` should come before `b`
      } else if (a['status'] != 'pending' && b['status'] == 'pending') {
        return 1; // `b` should come before `a`
      } else {
        return 0; // No change in order if both have same status
      }
    });

    if (requests.isEmpty) {
      return Center(child: Text('No requests found.'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var request = requests[index];
        String status = request['status'];
        String requestId = request.id;
        String userId = request['userId'];
        List wasteTypes = request['wasteTypes'];

        return Card(
          margin: EdgeInsets.all(8.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fetch user data
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading user data...');
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return Text('User not found.');
                    }

                    var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    String userName = userData['name'] ?? 'N/A';
                    String userEmail = userData['email'] ?? 'N/A';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User: $userName', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Email: $userEmail', style: TextStyle(fontSize: 16)),
                      ],
                    );
                  },
                ),
                SizedBox(height: 8.0),
                // Format the scheduled date to show only the date
                Text('Scheduled on ${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['scheduledDate']))}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.0),
                Text('Status: $status', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8.0),
                Text('Address: ${request['address']}', style: TextStyle(fontSize: 16)),
                Text('City: ${request['city']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8.0),
                Text('Waste Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...wasteTypes.map((waste) {
                  return Text('${waste['type']} - ${waste['weight']} kg');
                }).toList(),
                SizedBox(height: 8.0),
                
                ElevatedButton(
                  onPressed: () {
                    // Pass the necessary details to the CreateSpecialSchedulePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateSpecialSchedulePage(
                          requestId: request.id,
                          city: request['city'],
                          scheduledDate: request['scheduledDate'],
                          address: request['address'],
                          wasteTypes: request['wasteTypes'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 73, 204, 255),
                    textStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                  ),
                  child: Text('Create'), // Display "Create" text
                ),
                
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: () {
                      _markAsScheduleCreated(requestId);
                    },
                    child: Text('Pending'),
                  )
                else
                  Text('Schedule Created', style: TextStyle(color: Colors.green)),
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

  Future<void> _markAsScheduleCreated(String requestId) async {
  await FirebaseFirestore.instance
      .collection('specialWasteRequests')
      .doc(requestId)
      .update({'status': 'schedule created'});

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Schedule created for this request.')),
  );
}

}

// Sidebar widget
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
             Navigator.pop(context); // Close the drawer
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
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WasteCollectionSchedule()),
              );            },
          ),ListTile(
            leading: Icon(Icons.list),
            title: Text('Special Requests'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SpecialRequestsForSchedulingScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Special Schedules'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
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