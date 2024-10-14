import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'edit_my_requests_screen.dart';
import 'special_waste_collection_request_screen.dart';

class ViewRequestsScreen extends StatefulWidget {
  const ViewRequestsScreen({super.key});

  @override
  _ViewRequestsScreenState createState() => _ViewRequestsScreenState();
}

class _ViewRequestsScreenState extends State<ViewRequestsScreen> with SingleTickerProviderStateMixin {
  User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Requests',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildNewRequestCard(),
                    SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: Color(0xFF2E7D32),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF2E7D32),
                      tabs: [
                        Tab(text: 'Special Requests'),
                        Tab(text: 'Normal Requests'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSpecialRequests(),
                  _buildNormalRequests(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewRequestCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SpecialWasteRequestScreen()),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Special Waste Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Schedule a collection for special waste items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('specialWasteRequests')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('scheduledDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(
            child: Text(
              'No special requests found.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          );
        }

        return kIsWeb ? _buildWebLayout(requests) : _buildMobileLayout(requests);
      },
    );
  }

  Widget _buildNormalRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wasteCollectionRequests')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('requestedTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(
            child: Text(
              'No normal requests found.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          );
        }

        return kIsWeb ? _buildNormalWebLayout(requests) : _buildNormalMobileLayout(requests);
      },
    );
  }

  Widget _buildWebLayout(List<QueryDocumentSnapshot> requests) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: requests.map((request) => _buildRequestCard(request, isWeb: true)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(List<QueryDocumentSnapshot> requests) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildRequestCard(requests[index], isWeb: false),
    );
  }

  Widget _buildNormalWebLayout(List<QueryDocumentSnapshot> requests) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: requests.map((request) => _buildNormalRequestCard(request, isWeb: true)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalMobileLayout(List<QueryDocumentSnapshot> requests) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildNormalRequestCard(requests[index], isWeb: false),
    );
  }

  Widget _buildRequestCard(QueryDocumentSnapshot request, {required bool isWeb}) {
    String status = request['status'];
    String requestId = request.id;
    List wasteTypes = request['wasteTypes'];

    String formattedDate = DateFormat('MMM dd, yyyy').format(
      DateTime.parse(request['scheduledDate']),
    );

    Color statusColor = status == 'pending' ? Colors.orange : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.only(bottom: 16),
      child: Container(
        width: isWeb ? 350 : double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8F5E9)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                _buildStatusChip(status, statusColor),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Waste Types:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32)),
            ),
            SizedBox(height: 8),
            ..._buildWasteTypesList(wasteTypes),
            SizedBox(height: 16),
            if (status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Edit'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRequestScreen(requestId: requestId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete, size: 18),
                    label: Text('Delete'),
                    onPressed: () => _deleteRequest(requestId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalRequestCard(QueryDocumentSnapshot request, {required bool isWeb}) {
    String binId = request.get('binId') as String;
    bool isCollected = request.get('isCollected') as bool;
    bool isScheduled = request.get('isScheduled') as bool;
    Timestamp requestedTime = request.get('requestedTime') as Timestamp;

    String formattedDate = DateFormat('MMM dd, yyyy').format(requestedTime.toDate());

    String status = isCollected ? 'Collected' : (isScheduled ? 'Scheduled' : 'Pending');
    Color statusColor = isCollected ? Colors.green : (isScheduled ? Colors.blue : Colors.orange);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('bins').doc(binId).get(),
      builder: (context, snapshot) {
        String binName = 'Unknown Bin';
        if (snapshot.hasData && snapshot.data!.exists) {
          binName = snapshot.data!.get('nickname') as String? ?? 'Unnamed Bin';
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            width: isWeb ? 350 : double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFE8F5E9)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    _buildStatusChip(status, statusColor),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Bin: $binName',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  List<Widget> _buildWasteTypesList(List wasteTypes) {
    return wasteTypes.map<Widget>((waste) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              waste['type'],
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '${waste['weight']} kg',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ],
        ),
      );
    }).toList();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}