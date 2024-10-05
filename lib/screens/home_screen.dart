import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:percent_indicator/percent_indicator.dart'; // For visualizing percentages
import '../widgets/responsive_nav_bar.dart'; // Import the responsive nav bar
import '../screens/profile/profile_screen.dart';
import '../screens/admin/user_management_screen.dart'; // Import the UserManagementScreen
import 'admin/route_monitoring_screen.dart'; // Import the RouteMonitoringScreen
import '../screens/admin/schedule_waste_collection.dart'; // Import WasteCollectionDashboard
import '../../models/schedule_model.dart'; // Import the Schedule model
import '../screens/admin/confirm_bin_screen.dart'; // Import the ConfirmBinScreen

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
        _bins = binDocs.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    }
  }

  // Method to fetch the schedule data
  Future<Schedule?> _fetchSchedule() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .get();

    // Check if there are any documents
    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first; // Get the first document
      return Schedule.fromFirestore(doc); // Create Schedule object
    }
    return null; // Return null if no schedule is found
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
        child: _selectedIndex == 0
            ? _buildHomeContent()
            : ProfileScreen(),
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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserManagementScreen()), // Navigate to UserManagementScreen
              );
            },
            child: Text('User Management'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfirmBinScreen(), // Navigate to ConfirmBinScreen
                ),
              );
            },
            child: Text('Waste Bin Registration Requests'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WasteCollectionSchedule(),
                ),
              );
            },
            child: Text('Schedule Waste Collections'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Navigate to Waste Collection Requests
            },
            child: Text('Waste Collection Requests'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              Schedule? schedule = await _fetchSchedule(); // Fetch the schedule

              if (schedule != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteMonitoringScreen(routeId: '', wasteCollector: '',), // Pass the fetched schedule
                  ),
                );
              } else {
                // Handle the case when no schedule is found
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No schedules found')),
                );
              }
            },
            child: Text('Route Monitoring'),
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
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8, // Adjust the aspect ratio for better fitting
                  ),
                  itemCount: bins.length,
                  itemBuilder: (context, index) {
                    final binData = bins[index].data() as Map<String, dynamic>;
                    return _buildBinCard(binData);
                  },
                );
              },
            ),
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

  Widget _buildBinCard(Map<String, dynamic> binData) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Use spaceEvenly to balance content
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
            if (!(binData['confirmed'] ?? false))
              Text(
                'Pending',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
