import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalWasteByUserScreen extends StatefulWidget {
  @override
  _TotalWasteByUserScreenState createState() => _TotalWasteByUserScreenState();
}

class _TotalWasteByUserScreenState extends State<TotalWasteByUserScreen> {
  // Method to fetch all collected waste requests
  Stream<List<Map<String, dynamic>>> _fetchCollectedRequests() {
    return FirebaseFirestore.instance
        .collection('wasteCollectionRequests')
        .where('isCollected', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Method to aggregate waste by user
  Future<Map<String, double>> _aggregateWasteByUser(List<Map<String, dynamic>> requests) async {
    Map<String, double> wasteByUser = {};

    for (var request in requests) {
      String userId = request['userId'];
      double weight = request['collectedWeight']?.toDouble() ?? 0.0;

      if (wasteByUser.containsKey(userId)) {
        wasteByUser[userId] = wasteByUser[userId]! + weight;
      } else {
        wasteByUser[userId] = weight;
      }
    }

    return wasteByUser;
  }

  // Method to fetch user details
  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Waste Collected by Users'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchCollectedRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No waste collected yet.',
                style: TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
              ),
            );
          }

          return FutureBuilder<Map<String, double>>(
            future: _aggregateWasteByUser(snapshot.data!),
            builder: (context, aggregateSnapshot) {
              if (aggregateSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              }

              if (!aggregateSnapshot.hasData || aggregateSnapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No waste data available.',
                    style: TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
                  ),
                );
              }

              Map<String, double> wasteByUser = aggregateSnapshot.data!;

              return ListView.builder(
                itemCount: wasteByUser.keys.length,
                itemBuilder: (context, index) {
                  String userId = wasteByUser.keys.elementAt(index);
                  double totalWaste = wasteByUser[userId]!;

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchUserDetails(userId),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text('Loading user details...'),
                        );
                      }

                      if (!userSnapshot.hasData || userSnapshot.data == null) {
                        return ListTile(
                          title: Text('Unknown User'),
                          subtitle: Text('Total Waste: ${totalWaste.toStringAsFixed(2)} kg'),
                        );
                      }

                      String userName = userSnapshot.data!['name'] ?? 'Unknown Name';
                      String userEmail = userSnapshot.data!['email'] ?? 'No Email';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF4CAF50),
                          child: Text(userName[0].toUpperCase()),
                        ),
                        title: Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Email: $userEmail\nTotal Waste: ${totalWaste.toStringAsFixed(2)} kg'),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
