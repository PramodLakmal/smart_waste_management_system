import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the date
import 'edit_my_requests_screen.dart';

class ViewRequestsScreen extends StatefulWidget {
  @override
  _ViewRequestsScreenState createState() => _ViewRequestsScreenState();
}

class _ViewRequestsScreenState extends State<ViewRequestsScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _deleteRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('specialWasteRequests')
        .doc(requestId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request deleted successfully.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('specialWasteRequests')
            .where('userId', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No requests found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              String status = request['status'];
              String requestId = request.id;
              List wasteTypes = request['wasteTypes'];

              // Format the scheduled date to show only the date without time
              String formattedDate = DateFormat('yyyy-MM-dd').format(
                DateTime.parse(request['scheduledDate']),
              );

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Date: $formattedDate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 16,
                          color: status == 'pending' ? Colors.orange : Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Waste Types:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      // Displaying the waste types with their respective weights
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: wasteTypes.map<Widget>((waste) {
                          return Text(
                            '${waste['type']}: ${waste['weight']} kg',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 12),
                      // Conditionally show edit and delete buttons
                      if (status == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                // Navigate to edit screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditRequestScreen(requestId: requestId),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                _deleteRequest(requestId);
                              },
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Chip(
                            label: Text(
                              'Completed',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
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
}
