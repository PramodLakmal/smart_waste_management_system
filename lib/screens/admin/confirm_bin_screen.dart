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
                  String userAddress = '${user['address']}, ${user['city']}, ${user['state']}';

                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display bin image if available, otherwise a placeholder
                          bin['imageUrl'] != null
                              ? Image.network(
                                  bin['imageUrl'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image_not_supported); // Fallback icon if image doesn't load
                                  },
                                )
                              : Icon(Icons.delete_outline),
                          
                          SizedBox(height: 10),

                          // Display bin details
                          Text(bin['nickname'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Type: ${bin['type']}'),
                          Text('Weight: ${bin['weight']} kg'),
                          Text('Description: ${bin['description']}'),
                          Divider(),

                          // Display user information
                          Text('User: $userName'),
                          Text('Email: $userEmail'),
                          Text('Address: $userAddress'),

                          // Confirm and Delete buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!showConfirmed)
                                Flexible( // Wrap the Confirm button in Flexible
                                  child: ElevatedButton(
                                    onPressed: () => _confirmBin(bin.id),
                                    child: Text('Confirm'),
                                  ),
                                ),
                              SizedBox(width: 10),
                              Flexible( // Wrap the Delete button in Flexible
                                child: ElevatedButton(
                                  onPressed: () => _deleteBin(bin.id),
                                  child: Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red, // Red color for delete button
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
