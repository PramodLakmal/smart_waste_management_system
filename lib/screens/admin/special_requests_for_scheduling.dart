import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_waste_management_system/screens/admin/create_special_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/special_waste_collection_schedule.dart';
import 'package:smart_waste_management_system/screens/admin/waste_collection_schedule.dart';
import 'package:smart_waste_management_system/screens/home_screen.dart';

class SpecialRequestsForSchedulingScreen extends StatefulWidget {
  const SpecialRequestsForSchedulingScreen({super.key});

  @override
  _SpecialRequestsForSchedulingScreenState createState() => _SpecialRequestsForSchedulingScreenState();
}

class _SpecialRequestsForSchedulingScreenState extends State<SpecialRequestsForSchedulingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Special Waste Requests', style: TextStyle(color: const Color.fromARGB(221, 255, 255, 255))),
        backgroundColor: Colors.green[800],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              backgroundColor: Colors.green[700],
              child: Text('A', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
            ),
          ),
        ],
      ),
      drawer: Sidebar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('specialWasteRequests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;
          requests.sort((a, b) => a['status'] == 'pending' ? -1 : 1);

          if (requests.isEmpty) {
            return Center(child: Text('No requests found.', style: TextStyle(fontSize: 18)));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              String status = request['status'];
              String userId = request['userId'];
              List wasteTypes = request['wasteTypes'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  decoration: BoxDecoration(color: Colors.green[100]),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading user data...', style: TextStyle(fontStyle: FontStyle.italic));
                          }

                          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                            return Text('User not found.', style: TextStyle(color: Colors.red));
                          }

                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          String userName = userData['name'] ?? 'N/A';
                          String userEmail = userData['email'] ?? 'N/A';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(userEmail, style: TextStyle(color: Colors.grey[600])),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.parse(request['scheduledDate'])),
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                          ),
                          Chip(
                            label: Text(status.toUpperCase()),
                            backgroundColor: status == 'pending' ? Colors.green[200] : Colors.green[200],
                            labelStyle: TextStyle(color: status == 'pending' ? Colors.red[800] : Colors.red[800]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(request['address'], style: TextStyle(fontSize: 16)),
                      Text(request['city'], style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      SizedBox(height: 12),
                      Text('Waste Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...wasteTypes.map((waste) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text('${waste['type']} - ${waste['weight']} kg', style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      )),
                      SizedBox(height: 16),
                      if (status != 'schedule created')
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Create Schedule'),
                          onPressed: () {
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
                            foregroundColor: Colors.white, backgroundColor: Colors.green[500],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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
      SnackBar(
        content: Text('Schedule created for this request.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
// Sidebar widget
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

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
            isSelected: true,
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