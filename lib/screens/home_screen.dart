import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:percent_indicator/percent_indicator.dart'; // For visualizing percentages
import 'package:smart_waste_management_system/screens/admin/route_schedule_selection.dart';
import '../widgets/responsive_nav_bar.dart'; // Import the responsive nav bar
import '../screens/profile/profile_screen.dart';
import '../screens/admin/user_management_screen.dart'; // Import the UserManagementScreen
import 'admin/route_monitoring_screen.dart'; // Import the RouteMonitoringScreen
import 'admin/waste_collection_schedule.dart'; // Import WasteCollectionDashboard
import '../../models/schedule_model.dart'; // Import the Schedule model
import '../screens/admin/confirm_bin_screen.dart'; // Import the ConfirmBinScreen
import '../screens/admin/waste_collection_requests_screen.dart'; // Import the WasteCollectionRequestsScreen
import '../screens/user/special_waste_collection_request_screen.dart'; // Import the SpecialWasteRequestScreen
import '../screens/user/view_my_requests_screen.dart';
import '../screens/admin/view_special_requests_screen.dart'; // Import the AdminViewRequestsScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isUser = false;
  List<Map<String, dynamic>> _bins = [];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchUserBins();
  }

  Future<void> _checkUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        if (userDoc['role'] == 'admin') {
          _isAdmin = true;
        } else if (userDoc['role'] == 'user') {
          _isUser = true;
        }
      });
    }
  }

  Future<void> _fetchUserBins() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      QuerySnapshot binDocs = await FirebaseFirestore.instance
          .collection('bins')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        _bins = binDocs.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  }

  // Method to fetch the schedule data
  Future<Schedule?> _fetchSchedule() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('schedules').get();

    // Check if there are any documents
    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first; // Get the first document
      return Schedule.fromFirestore(doc); // Create Schedule object
    }
    return null; // Return null if no schedule is found
  }

  // Method to send waste collection request
  Future<void> _sendWasteCollectionRequest(
      String binId, String userId, String binNickname) async {
    try {
      await FirebaseFirestore.instance
          .collection('wasteCollectionRequests')
          .add({
        'userId': userId,
        'binId': binId,
        'requestedTime': FieldValue.serverTimestamp(),
        'isCollected': false, // Initially set to false
      });

      // Update the bin's collectionRequestSent status to true
      await FirebaseFirestore.instance.collection('bins').doc(binId).update({
        'collectionRequestSent': true,
      });

      // Show a snackbar with the bin nickname
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Waste collection request sent for bin $binNickname')),
      );
    } catch (e) {
      print('Error sending waste collection request: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Home'),
    ),
    drawer: kIsWeb
        ? ResponsiveNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          )
        : null,
    body: Center(
      // Update this logic to handle the new screen display for Admin and User
      child: _selectedIndex == 0
          ? _buildHomeContent() // Home content
          : _isAdmin
              ? ProfileScreen() // Admin sees ProfileScreen
              : _selectedIndex == 1
                  ? ViewRequestsScreen() // User sees ViewRequestsScreen
                  : ProfileScreen(), // Default to ProfileScreen for users
    ),
    bottomNavigationBar: !kIsWeb
        ? ResponsiveNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          )
        : null,
  );
}


  Widget _buildHomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Welcome to the Waste Management System',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        if (_isAdmin) ...[
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: EdgeInsets.all(10),
              children: [
                _buildAdminCard(
                  icon: Icons.people,
                  title: 'User Management',
                  description: 'Manage Users in the System',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.add_box,
                  title: 'Bin Registration',
                  description: 'Review and Confirm Bins',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmBinScreen(),
                      ),
                    );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.schedule,
                  title: 'Waste Collection Schedule',
                  description: 'Schedule Waste Collection',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WasteCollectionSchedule(),
                      ),
                    );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.list,
                  title: 'View Collection Requests',
                  description: 'View all Waste Collection Requests',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WasteCollectionRequestsScreen(),
                      ),
                    );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.list,
                  title: 'View Special Collection Requests',
                  description: 'View all Special Waste Collection Requests',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminViewRequestsScreen(),
                      ),
                    );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.map,
                  title: 'Route Monitoring',
                  description: 'Monitor Waste Collection Routes',
                  onTap: () async {
                    Schedule? schedule = await _fetchSchedule();
                    if (schedule != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteScheduleSelection(
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No schedules found')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        if (_isUser) ...[
          Text(
            'My Bins',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bins')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final bins = snapshot.data!.docs;
                if (bins.isEmpty) {
                  return Center(child: Text('No bins added yet.'));
                }
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                        0.8, // Adjust the aspect ratio for better fitting
                  ),
                  itemCount: bins.length,
                  itemBuilder: (context, index) {
                    final binData =
                        bins[index].data() as Map<String, dynamic>;
                    return _buildBinCard(binData);
                  },
                );
              },
            ),
          ),
          ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialWasteRequestScreen(), // Navigate to the special request screen
      ),
    );
  },
  child: Text('Special Waste Collection Request'),
),
        ],
        if (!_isAdmin && !_isUser)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'You do not have access to management features.',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminCard(
      {required IconData icon,
      required String title,
      required String description,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBinCard(Map<String, dynamic> binData) {
    if (binData['filledPercentage'] == 100 &&
        binData['userId'] != null &&
        !(binData['collectionRequestSent'] ?? false)) {
      _sendWasteCollectionRequest(
          binData['binId'], binData['userId'], binData['nickname']);
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              binData['nickname'] ?? 'Unnamed Bin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              binData['type'] ?? 'Unknown Type',
              style: TextStyle(color: Colors.grey),
            ),
            Flexible(
              child: CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: (binData['filledPercentage'] ?? 0) / 100,
                center: Text(
                  '${binData['filledPercentage'] ?? 0}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                progressColor: Colors.green,
                backgroundColor: const Color.fromARGB(255, 210, 210, 210),
              ),
            ),
            SizedBox(height: 10),
            if (binData['filledPercentage'] == 100)
              Text(
                'Collection Request Sent',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            if (!(binData['confirmed'] ?? false))
              Text(
                'Pending',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
