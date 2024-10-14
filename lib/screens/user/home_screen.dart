import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smart_waste_management_system/screens/user/payment.dart';
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
    _screens.add(Payment());
    _screens.add(ProfileScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? _buildWebAppBar() : _buildMobileAppBar(),
      body: _screens[_currentIndex],
      bottomNavigationBar: !kIsWeb ? _buildMobileBottomNavBar() : null,
    );
  }

  AppBar _buildWebAppBar() {
    return AppBar(
      title:
          Text('Smart Waste Management', style: TextStyle(color: Colors.white)),
      backgroundColor: Color(0xFF2E7D32),
      actions: [
        ..._buildWebNavBar(),
        SizedBox(width: 20),
      ],
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      title: Text('Smart Waste', style: TextStyle(color: Colors.white)),
      backgroundColor: Color(0xFF2E7D32),
      elevation: 0,
    );
  }

  List<Widget> _buildWebNavBar() {
    return [
      _buildWebNavBarItem('Home', 0, Icons.home),
      _buildWebNavBarItem('Collection Requests', 1, Icons.request_page),
      _buildWebNavBarItem('Payments', 2, Icons.payment),
      _buildWebNavBarItem('Profile', 3, Icons.person),
    ];
  }

  Widget _buildWebNavBarItem(String title, int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: TextButton.icon(
        onPressed: () => setState(() => _currentIndex = index),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNavBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.request_page), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb) _buildWebCarousel() else _buildMobileCarousel(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bins',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32)),
                ),
                SizedBox(height: 16),
                _buildCategorizedBinsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCarousel() {
    return Container(
      height: 400,
      child: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 400.0,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              viewportFraction: 1.0,
            ),
            items: carouselImages.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCarousel() {
    return Container(
      height: 200,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 200.0,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          viewportFraction: 0.8,
        ),
        items: carouselImages.map((imageUrl) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: AssetImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorizedBinsList() {
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

        Map<String, List<QueryDocumentSnapshot>> categorizedBins = {};
        for (var bin in bins) {
          final binData = bin.data() as Map<String, dynamic>;
          final type = binData['type'] ?? 'Unknown';
          if (!categorizedBins.containsKey(type)) {
            categorizedBins[type] = [];
          }
          categorizedBins[type]!.add(bin);
        }

        if (kIsWeb) {
          return _buildWebCategorizedBinsList(categorizedBins);
        } else {
          return _buildMobileCategorizedBinsList(categorizedBins);
        }
      },
    );
  }

  Widget _buildWebCategorizedBinsList(Map<String, List<QueryDocumentSnapshot>> categorizedBins) {
    List<Widget> columns = [];
    List<Widget> currentColumn = [];

    categorizedBins.entries.forEach((entry) {
      currentColumn.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                entry.key,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
            ),
            _buildBinsGrid(entry.value),
            SizedBox(height: 16),
          ],
        ),
      );

      if (currentColumn.length == 2 || entry.key == categorizedBins.keys.last) {
        columns.add(
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: currentColumn,
            ),
          ),
        );
        currentColumn = [];
      }
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Widget _buildMobileCategorizedBinsList(Map<String, List<QueryDocumentSnapshot>> categorizedBins) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorizedBins.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                entry.key,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
            ),
            _buildBinsGrid(entry.value),
            SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBinCard(Map<String, dynamic> binData) {
    final filledPercentage = (binData['filledPercentage'] ?? 0) / 100;
    final isFull = filledPercentage >= 0.9;
    final isPending = !(binData['confirmed'] ?? false);
    final weight = binData['weight'] ?? 0.0;
    final isCollectionRequested = binData['collectionRequestSent'] ?? false;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(kIsWeb ? 12 : 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8F5E9)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              binData['nickname'] ?? 'Unnamed Bin',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32)),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: kIsWeb ? 8 : 4),
            Expanded(
              child: Center(
                child: CircularPercentIndicator(
                  radius: kIsWeb ? 60.0 : 55.0,
                  lineWidth: 8.0,
                  percent: filledPercentage,
                  center: Text(
                    "${(filledPercentage * 100).toStringAsFixed(0)}%",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  progressColor: _getProgressColor(filledPercentage),
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                ),
              ),
            ),
            SizedBox(height: kIsWeb ? 8 : 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${weight.toStringAsFixed(1)}${kIsWeb ? ' kg' : 'kg'}",
                  style: TextStyle(
                      fontSize: kIsWeb ? 12 : 10, color: Colors.grey[600]),
                ),
                _buildStatusChip(isFull, isPending, isCollectionRequested),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isFull, bool isPending, bool isCollectionRequested) {
    if (isCollectionRequested) {
      return _buildChip(
          kIsWeb ? 'Collection Requested' : 'Requested', Colors.blue);
    } else if (isFull) {
      return _buildChip('Full', Colors.red);
    } else if (isPending) {
      return _buildChip('Pending', Colors.orange);
    } else {
      return _buildChip('Active', Color(0xFF4CAF50));
    }
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: kIsWeb ? 10 : 9,
            color: color,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBinsGrid(List<QueryDocumentSnapshot> bins) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kIsWeb ? 3 : 2,
        crossAxisSpacing: kIsWeb ? 16 : 12,
        mainAxisSpacing: kIsWeb ? 16 : 12,
        childAspectRatio: kIsWeb ? 0.9 : 0.85,
      ),
      itemCount: bins.length,
      itemBuilder: (context, index) {
        final binData = bins[index].data() as Map<String, dynamic>;
        _checkAndSendRequest(binData);
        return _buildBinCard(binData);
      },
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
    if (percentage < 0.5) return Color(0xFF4CAF50);
    if (percentage < 0.75) return Colors.orange;
    return Colors.red;
  }
}
