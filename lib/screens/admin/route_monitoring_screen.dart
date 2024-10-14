import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class BinIdsScreen extends StatefulWidget {
  final List<dynamic> binIds;
  final String wasteCollectorId;
  final String wasteCollector;

  const BinIdsScreen({super.key, 
    required this.binIds,
    required this.wasteCollectorId,
    required this.wasteCollector,
  });

  @override
  _BinIdsScreenState createState() => _BinIdsScreenState();
}

class _BinIdsScreenState extends State<BinIdsScreen> {
  bool _showCollected = false;

  // Fetch waste collection requests filtered by wasteCollectorId and binIds
  Stream<QuerySnapshot> _fetchRequests() {
    if (widget.binIds.isEmpty) {
      print("binIds is empty!");
      return Stream.empty();
    }

    print("Fetching requests for binIds: ${widget.binIds}");

    return FirebaseFirestore.instance
        .collection('wasteCollectionRequests')
        .where('isCollected', isEqualTo: _showCollected)
        .where('binId', whereIn: widget.binIds)
        .snapshots();
  }

  // Fetch user details by userId
  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  // Fetch bin details by binId
  Future<Map<String, dynamic>?> _fetchBinDetails(String binId) async {
    try {
      DocumentSnapshot binDoc = await FirebaseFirestore.instance.collection('bins').doc(binId).get();
      return binDoc.exists ? binDoc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching bin details: $e');
      return null;
    }
  }

  // Method to mark a request as collected and store it in 'collectedWastes'
  Future<void> _markAsCollected(String requestId, String binId) async {
    try {
      // Fetch the waste collection request details
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance.collection('wasteCollectionRequests').doc(requestId).get();
      if (!requestDoc.exists) {
        print('Waste collection request not found.');
        return;
      }
      Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;

      // Fetch the user details
      String userId = requestData['userId'];
      Map<String, dynamic>? userData = await _fetchUserDetails(userId);
      if (userData == null) {
        print('User data not found.');
        return;
      }

      // Fetch the bin details
      Map<String, dynamic>? binData = await _fetchBinDetails(binId);
      if (binData == null) {
        print('Bin data not found.');
        return;
      }

      // Extract necessary fields
      String collectorId = widget.wasteCollectorId;
      String collectorName = widget.wasteCollector;
      String uid = userId;
      String name = userData['name'] ?? 'Unknown Name';
      String wasteCollector = collectorName;
      double weight = binData['weight'] ?? 0.0;
      String type = binData['type'] ?? 'Unknown Type';
      String binIdCollected = binId;

      // Save the collected waste data to 'collectedWastes' collection
      await FirebaseFirestore.instance.collection('collectedWastes').add({
        'collectorId': collectorId,
        'uid': uid,
        'name': name,
        'wasteCollector': wasteCollector,
        'weight': weight,
        'type': type,
        'binId': binIdCollected,
        'collectedTime': FieldValue.serverTimestamp(), // Save the collection time
      });

      // Update waste collection request to mark as collected
      await FirebaseFirestore.instance.collection('wasteCollectionRequests').doc(requestId).update({
        'isCollected': true,
      });

      // Update the bin: set collectionRequestSent to false and filledPercentage to 0
      await FirebaseFirestore.instance.collection('bins').doc(binId).update({
        'collectionRequestSent': false,
        'filledPercentage': 0,
      });

      // Update the schedule status to "completed"
      await _updateSchedule(binId);

      // Show a snackbar confirming the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as collected and stored in collectedWastes.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      print('Error marking as collected: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as collected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update the schedule to mark it as collected
  Future<void> _updateSchedule(String binId) async {
    try {
      // Fetch the schedule where this binId is present in the bins array
      QuerySnapshot scheduleSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('bins', arrayContains: binId)
          .get();

      if (scheduleSnapshot.docs.isNotEmpty) {
        // Assuming only one schedule contains this binId
        String scheduleId = scheduleSnapshot.docs.first.id;

        // Update the schedule's status to 'completed'
        await FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update({
          'status': 'completed',
        });
        print('Schedule $scheduleId marked as collected.');
      } else {
        print('No schedule found for binId $binId.');
      }
    } catch (e) {
      print('Error updating schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Collection - ${widget.wasteCollector}'),
        backgroundColor: Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: Icon(_showCollected ? Icons.unarchive : Icons.archive),
            onPressed: () {
              setState(() {
                _showCollected = !_showCollected;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                _showCollected ? 'No collected requests.' : 'No pending requests.',
                style: TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requestData = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final binId = requestData['binId'];
              final userId = requestData['userId'];
              final requestedTime = requestData['requestedTime']?.toDate() ?? DateTime.now();

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                color: Colors.grey[200],
                child: ExpansionTile(
                  title: FutureBuilder<Map<String, dynamic>?>( 
                    future: _fetchUserDetails(userId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Text('Loading user details...', style: TextStyle(color: Color(0xFF4CAF50)));
                      }

                      final userData = userSnapshot.data;
                      final userName = userData?['name'] ?? 'Unknown Name';
                      return Text(userName, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)));
                    },
                  ),
                  subtitle: Text(
                    'Requested on: ${DateFormat('MMM dd, yyyy HH:mm').format(requestedTime)}',
                    style: TextStyle(color: Colors.black54),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<Map<String, dynamic>?>( 
                            future: _fetchUserDetails(userId),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return Text('Loading user details...');
                              }

                              final userData = userSnapshot.data;
                              final address = userData?['address'] ?? 'Unknown Address';
                              final city = userData?['city'] ?? 'Unknown City';
                              final userEmail = userData?['email'] ?? 'Unknown Email';
                              return Text('Email: $userEmail\nAddress: $address\nCity: $city', style: TextStyle(color: Colors.black87));
                            },
                          ),
                          SizedBox(height: 8),
                          FutureBuilder<Map<String, dynamic>?>( 
                            future: _fetchBinDetails(binId),
                            builder: (context, binSnapshot) {
                              if (!binSnapshot.hasData) {
                                return Text('Loading bin details...');
                              }

                              final binData = binSnapshot.data;
                              if (binData == null) {
                                return Text('Error loading bin data.', style: TextStyle(color: Colors.red));
                              }

                              final binType = binData['type'] ?? 'Unknown Type';
                              final binWeight = binData['weight']?.toString() ?? 'Unknown Weight';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bin Type: $binType', style: TextStyle(color: Colors.black87)),
                                  Text('Weight: $binWeight', style: TextStyle(color: Colors.black87)),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          if (!_showCollected)
                            ElevatedButton(
                              onPressed: () => _markAsCollected(requestId, binId),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Color(0xFF4CAF50),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text('Mark as Collected'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
