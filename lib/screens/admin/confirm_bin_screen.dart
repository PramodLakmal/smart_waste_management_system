import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmBinScreen extends StatefulWidget {
  const ConfirmBinScreen({super.key});

  @override
  _ConfirmBinScreenState createState() => _ConfirmBinScreenState();
}

class _ConfirmBinScreenState extends State<ConfirmBinScreen> {
  final CollectionReference binsRef =
      FirebaseFirestore.instance.collection('bins');
  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('users');

  bool showConfirmed = false;

  Future<void> _confirmBin(String binId) async {
    await binsRef.doc(binId).update({'confirmed': true});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bin confirmed successfully!'),
      backgroundColor: Color(0xFF4CAF50),
    ));
  }

  Future<void> _deleteBin(String binId) async {
    await binsRef.doc(binId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bin deleted successfully!'),
      backgroundColor: Color(0xFF4CAF50),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Bins', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWebLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 200,
          color: Color(0xFF4CAF50),
          child: Column(
            children: [
              SizedBox(height: 20),
              _buildSidebarButton(
                  'Unconfirmed Bins', Icons.pending_actions, false),
              _buildSidebarButton('Confirmed Bins', Icons.check_circle, true),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: _buildBinList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Tab bar for mobile
        Container(
          color: Color(0xFF4CAF50),
          child: Row(
            children: [
              Expanded(child: _buildMobileTab('Unconfirmed', false)),
              Expanded(child: _buildMobileTab('Confirmed', true)),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: _buildBinList(isMobile: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarButton(String title, IconData icon, bool confirmed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon,
            color: showConfirmed == confirmed ? Colors.white : Colors.black54),
        label: Text(title,
            style: TextStyle(
                color: showConfirmed == confirmed
                    ? Colors.white
                    : Colors.black54)),
        style: ElevatedButton.styleFrom(
          backgroundColor: showConfirmed == confirmed
              ? Color(0xFF2E7D32)
              : Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        onPressed: () => setState(() => showConfirmed = confirmed),
      ),
    );
  }

  Widget _buildMobileTab(String title, bool confirmed) {
    return InkWell(
      onTap: () => setState(() => showConfirmed = confirmed),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: showConfirmed == confirmed
                  ? Colors.white
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: showConfirmed == confirmed ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBinList({bool isMobile = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: binsRef.where('confirmed', isEqualTo: showConfirmed).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              showConfirmed
                  ? 'No confirmed bins available.'
                  : 'No bins to confirm.',
              style: TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
            ),
          );
        }

        final bins = snapshot.data!.docs;

        if (isMobile) {
          return ListView.builder(
            itemCount: bins.length,
            itemBuilder: (context, index) => _buildMobileBinCard(bins[index]),
          );
        } else {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            padding: EdgeInsets.all(16),
            itemCount: bins.length,
            itemBuilder: (context, index) => _buildWebBinCard(bins[index]),
          );
        }
      },
    );
  }

  Widget _buildWebBinCard(DocumentSnapshot bin) {
    return FutureBuilder<DocumentSnapshot>(
      future: usersRef.doc(bin['userId']).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Card(child: Center(child: CircularProgressIndicator()));
        }

        final user = userSnapshot.data!;
        String userName = user['name'] ?? 'Unknown';
        String userEmail = user['email'] ?? 'Unknown';
        String userAddress = '${user['address']}, ${user['city']}';

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bin['nickname'],
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32)),
                ),
                SizedBox(height: 8),
                Text('Type: ${bin['type']}'),
                Text('Weight: ${bin['weight']} kg'),
                Text('Description: ${bin['description']}'),
                Divider(height: 16),
                Text('User: $userName'),
                Text('Email: $userEmail'),
                Text('Address: $userAddress', overflow: TextOverflow.ellipsis),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!showConfirmed)
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => _confirmBin(bin.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color(0xFF4CAF50), // Button background color
                        ),
                      ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        'Delete',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                      onPressed: () => _deleteBin(bin.id),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileBinCard(DocumentSnapshot bin) {
    return FutureBuilder<DocumentSnapshot>(
      future: usersRef.doc(bin['userId']).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Card(child: Center(child: CircularProgressIndicator()));
        }

        final user = userSnapshot.data!;
        String userName = user['name'] ?? 'Unknown';
        String userEmail = user['email'] ?? 'Unknown';
        String userAddress = '${user['address']}, ${user['city']}';

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bin['nickname'],
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32)),
                ),
                SizedBox(height: 8),
                Text('Type: ${bin['type']}'),
                Text('Weight: ${bin['weight']} kg'),
                Text('Description: ${bin['description']}'),
                Divider(height: 16),
                Text('User: $userName'),
                Text('Email: $userEmail'),
                Text('Address: $userAddress'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!showConfirmed)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text(
                            'Confirm',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                          onPressed: () => _confirmBin(bin.id),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF50)),
                        ),
                      ),
                    if (!showConfirmed) SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.delete, color: Colors.white),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                        onPressed: () => _deleteBin(bin.id),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
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
  }
}
