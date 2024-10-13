import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmBinScreen extends StatefulWidget {
  @override
  _ConfirmBinScreenState createState() => _ConfirmBinScreenState();
}

class _ConfirmBinScreenState extends State<ConfirmBinScreen> {
  final CollectionReference binsRef = FirebaseFirestore.instance.collection('bins');
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  bool showConfirmed = false; // Toggle between confirmed and unconfirmed bins

  // Function to confirm a bin
  Future<void> _confirmBin(String binId) async {
    await binsRef.doc(binId).update({'confirmed': true});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bin confirmed successfully!'),
    ));
  }

  // Function to delete a bin
  Future<void> _deleteBin(String binId) async {
    await binsRef.doc(binId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bin deleted successfully!'),
    ));
  }

  // Function to fetch user data by userId
  Future<DocumentSnapshot> _getUserData(String userId) async {
    return await usersRef.doc(userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Bins'),
        actions: [
          IconButton(
            icon: Icon(showConfirmed ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                showConfirmed = !showConfirmed; // Toggle between confirmed and unconfirmed bins
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: binsRef.where('confirmed', isEqualTo: showConfirmed).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(showConfirmed ? 'No confirmed bins available.' : 'No bins to confirm.'),
            );
          }

          // List of bins to confirm
          final bins = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bins.length,
            itemBuilder: (context, index) {
              final bin = bins[index];
              return FutureBuilder<DocumentSnapshot>(
                future: _getUserData(bin['userId']),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: Text('Loading user data...'),
                    );
                  }

                  // Extract user data
                  final user = userSnapshot.data!;
                  String userName = user['name'] ?? 'Unknown';
                  String userEmail = user['email'] ?? 'Unknown';
                  String userAddress = '${user['address']}, ${user['city']}';

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bin details
                          Text(
                            bin['nickname'],
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Type: ${bin['type']}', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Weight: ${bin['weight']} kg', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Description: ${bin['description']}', style: TextStyle(fontSize: 16)),
                          Divider(height: 30, thickness: 1),

                          // User information
                          Text('User Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 8),
                          Text('Name: $userName', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Email: $userEmail', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Address: $userAddress', style: TextStyle(fontSize: 16)),

                          // Action buttons
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!showConfirmed)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _confirmBin(bin.id),
                                    child: Text('Confirm'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _deleteBin(bin.id),
                                  child: Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
