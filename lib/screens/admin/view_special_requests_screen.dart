import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminViewRequestsScreen extends StatefulWidget {
  const AdminViewRequestsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminViewRequestsScreenState createState() => _AdminViewRequestsScreenState();
}

class _AdminViewRequestsScreenState extends State<AdminViewRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Special Waste Collection Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('specialWasteRequests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

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
                      }),
                      SizedBox(height: 8.0),
                      if (status == 'pending')
                        ElevatedButton(
                          onPressed: () {
                            _markAsCompleted(requestId);
                          },
                          child: Text('Mark as Completed'),
                        )
                      else
                        Text('Completed', style: TextStyle(color: Colors.green)),
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

  Future<void> _markAsCompleted(String requestId) async {
    await FirebaseFirestore.instance
        .collection('specialWasteRequests')
        .doc(requestId)
        .update({'status': 'completed'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request marked as completed.')),
    );
  }
}
