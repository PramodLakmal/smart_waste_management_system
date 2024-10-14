import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'add_vehicle_form.dart';

class AdminWasteDashboard extends StatefulWidget {
  const AdminWasteDashboard({super.key});

  @override
  _AdminWasteDashboardState createState() => _AdminWasteDashboardState();
}

class _AdminWasteDashboardState extends State<AdminWasteDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = Color(0xFF2E7D32);
  final Color secondaryColor = Color(0xFF4CAF50);
  final Color backgroundColor = Colors.grey[200]!;
  final Color accentColor = Colors.red[100]!;
  final Color cardColor = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Updated to 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Admin Waste Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          tabs: [
            Tab(text: 'Special Schedule Waste'),
            Tab(text: 'Normal Schedule Waste'),
            Tab(text: 'Vehicle Tracking'), // New Vehicle Tracking tab
          ],
          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WasteListView(
            collectionName: 'collectedSpecialWastes',
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            cardColor: cardColor,
            accentColor: accentColor,
          ),
          WasteListView(
            collectionName: 'collectedWastes',
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            cardColor: cardColor,
            accentColor: accentColor,
          ),
          VehicleTrackingView(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            cardColor: cardColor,
          ), // New VehicleTrackingView widget
        ],
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddVehicleForm()),
        );
      },
      backgroundColor: primaryColor,
      child: Icon(Icons.add),
    ),
    );
  }
}

class WasteListView extends StatelessWidget {
  final String collectionName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor;
  final Color secondaryColor;
  final Color cardColor;
  final Color accentColor;

  WasteListView({super.key, 
    required this.collectionName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.cardColor,
    required this.accentColor,
  });

  Stream<Map<String, dynamic>> _calculateTotalWaste() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      Map<String, dynamic> totals = {};
      for (var doc in snapshot.docs) {
        String collectorId = doc['collectorId'];
        String collectorName = doc['wasteCollector'];
        double weight = (doc['weight'] ?? 0).toDouble();

        if (totals.containsKey(collectorId)) {
          totals[collectorId]['totalWeight'] += weight;
        } else {
          totals[collectorId] = {
            'collectorName': collectorName,
            'totalWeight': weight,
          };
        }
      }
      return totals;
    });
  }

  Future<void> _deleteWaste(String docId) async {
    await _firestore.collection(collectionName).doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _calculateTotalWaste(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: secondaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No waste collected.', style: TextStyle(color: primaryColor, fontSize: 18)));
        }

        Map<String, dynamic> totals = snapshot.data!;
        return ListView.builder(
          itemCount: totals.length,
          itemBuilder: (context, index) {
            String collectorId = totals.keys.elementAt(index);
            String collectorName = totals[collectorId]['collectorName'];
            double totalWeight = totals[collectorId]['totalWeight'];

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              child: ExpansionTile(
                title: Text(
                  collectorName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                ),
                subtitle: Text(
                  'Total Waste: ${totalWeight.toStringAsFixed(2)} kg',
                  style: TextStyle(color: cardColor),
                ),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection(collectionName)
                        .where('collectorId', isEqualTo: collectorId)
                        .orderBy('collectedTime', descending: true)
                        .snapshots(),
                    builder: (context, wasteSnapshot) {
                      if (wasteSnapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator(color: secondaryColor)),
                        );
                      }

                      if (!wasteSnapshot.hasData || wasteSnapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('No waste entries for this collector.', style: TextStyle(color: secondaryColor)),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: wasteSnapshot.data!.docs.length,
                        itemBuilder: (context, wasteIndex) {
                          var wasteDoc = wasteSnapshot.data!.docs[wasteIndex];
                          String wasteType = wasteDoc['type'] ?? 'Unknown';
                          double weight = (wasteDoc['weight'] ?? 0).toDouble();
                          Timestamp collectedTime = wasteDoc['collectedTime'];
                          String docId = wasteDoc.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(wasteType, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                                      SizedBox(height: 4),
                                      Text('${weight.toStringAsFixed(2)} kg', style: TextStyle(color: secondaryColor)),
                                      Text(
                                        'Collected: ${DateFormat('MMM d, yyyy HH:mm').format(collectedTime.toDate())}',
                                        style: TextStyle(color: secondaryColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    bool? confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete Waste Entry'),
                                        content: Text('Are you sure you want to delete this waste entry?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: Text('Cancel', style: TextStyle(color: primaryColor)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await _deleteWaste(docId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Waste entry deleted'),
                                            backgroundColor: secondaryColor,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to delete waste entry'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class VehicleTrackingView extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Color cardColor;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  VehicleTrackingView({super.key, 
    required this.primaryColor,
    required this.secondaryColor,
    required this.cardColor,
  });

  Stream<QuerySnapshot> _getVehicleData() {
    return _firestore.collection('vehicleTracking').snapshots(); // Firestore collection for vehicles
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getVehicleData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: secondaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No vehicles are currently tracked.', style: TextStyle(color: primaryColor, fontSize: 18)));
        }

        var vehicles = snapshot.data!.docs;
        return ListView.builder(
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            var vehicleDoc = vehicles[index];
            String vehicleId = vehicleDoc['vehicleId'];
            String status = vehicleDoc['status'] ?? 'Unknown';
            GeoPoint location = vehicleDoc['location'];
            String driverName = vehicleDoc['driverName'] ?? 'Unknown';

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.local_shipping, color: primaryColor),
                title: Text('Vehicle ID: $vehicleId', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver: $driverName', style: TextStyle(color: secondaryColor)),
                    Text('Status: $status', style: TextStyle(color: secondaryColor)),
                    Text('Location: Lat: ${location.latitude}, Lng: ${location.longitude}', style: TextStyle(color: secondaryColor, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
