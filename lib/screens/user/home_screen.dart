import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smart_waste_management_system/screens/user/payment.dart';
import '../user/special_waste_collection_request_screen.dart';
import '../user/view_my_requests_screen.dart';
import '../profile/profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [];

  final List<String> carouselImages = [
    'images/1.jpg',
    'images/3.jpg',
    'images/2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _screens.add(_buildHome());
    _screens.add(ViewRequestsScreen());
    _screens.add(ProfileScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Management'),
        backgroundColor: Colors.green,
        actions: kIsWeb ? _buildWebNavBar() : [],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: !kIsWeb
          ? BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.request_page), label: 'Special Requests'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
            )
          : null,
    );
  }

  List<Widget> _buildWebNavBar() {
    return [
      _buildWebNavBarItem('Home', 0),
      _buildWebNavBarItem('Special Requests', 1),
      _buildWebNavBarItem('Profile', 2),
    ];
  }

  Widget _buildWebNavBarItem(String title, int index) {
    bool isSelected = _currentIndex == index;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: TextButton(
        onPressed: () => setState(() => _currentIndex = index),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: carouselImages.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    child: Image.asset(imageUrl, fit: BoxFit.cover),
                  );
                },
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bins',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildBinsList(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SpecialWasteRequestScreen(), // Navigate to the special request screen
                  ),
                );
              },
              child: Text('Special Waste Collection Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bins')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final bins = snapshot.data!.docs;
        if (bins.isEmpty) {
          return Center(child: Text('No bins added yet.'));
        }
        return kIsWeb ? _buildWebGrid(bins) : _buildMobileList(bins);
      },
    );
  }

  Widget _buildWebGrid(List<QueryDocumentSnapshot> bins) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: bins.length,
      itemBuilder: (context, index) {
        final binData = bins[index].data() as Map<String, dynamic>;
        _checkAndSendRequest(binData);
        return _buildBinCard(binData, isWeb: true);
      },
    );
  }

  Widget _buildMobileList(List<QueryDocumentSnapshot> bins) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: bins.length,
      itemBuilder: (context, index) {
        final binData = bins[index].data() as Map<String, dynamic>;
        _checkAndSendRequest(binData);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildBinCard(binData, isWeb: false),
        );
      },
    );
  }

  Widget _buildBinCard(Map<String, dynamic> binData, {required bool isWeb}) {
    final filledPercentage = (binData['filledPercentage'] ?? 0) / 100;
    final isFull = filledPercentage >= 0.9;
    final isPending = !(binData['confirmed'] ?? false);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE0F2F1)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    binData['nickname'] ?? 'Unnamed Bin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    binData['type'] ?? 'Unknown',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (isWeb)
              Center(
                child: CircularPercentIndicator(
                  radius: 60.0,
                  lineWidth: 10.0,
                  percent: filledPercentage,
                  center: Text(
                    "${(filledPercentage * 100).toStringAsFixed(0)}%",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  progressColor: _getProgressColor(filledPercentage),
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                ),
              )
            else
              LinearPercentIndicator(
                lineHeight: 8.0,
                percent: filledPercentage,
                progressColor: _getProgressColor(filledPercentage),
                backgroundColor: Colors.grey[300],
                barRadius: Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isWeb)
                  Text(
                    "${(filledPercentage * 100).toStringAsFixed(0)}% Full",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                if (isFull)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Collection Requested',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  )
                else if (isPending)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndSendRequest(Map<String, dynamic> binData) {
    if (binData['filledPercentage'] >= 90 &&
        binData['userId'] != null &&
        !(binData['collectionRequestSent'] ?? false)) {
      _sendWasteCollectionRequest(
          binData['binId'], binData['userId'], binData['nickname']);
    }
  }

  Future<void> _sendWasteCollectionRequest(
      String binId, String userId, String binNickname) async {
    try {
      await FirebaseFirestore.instance
          .collection('wasteCollectionRequests')
          .add({
        'userId': userId,
        'binId': binId,
        'requestedTime': FieldValue.serverTimestamp(),
        'isCollected': false,
        'isScheduled': false,
        'paymentStatus': 'pending',
      });
      await FirebaseFirestore.instance.collection('bins').doc(binId).update({
        'collectionRequestSent': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Waste collection request sent for bin $binNickname')),
      );
    } catch (e) {
      print('Error sending waste collection request: $e');
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.5) return Colors.green;
    if (percentage < 0.75) return Colors.orange;
    return Colors.red;
  }
}
