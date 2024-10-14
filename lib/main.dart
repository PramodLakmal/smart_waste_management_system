import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/admin/waste_collector_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bin/add_bin_screen.dart';
import 'screens/user/view_my_requests_screen.dart';
import 'screens/user/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase based on the platform (Web or Mobile)
  if (kIsWeb) {
    // Web-specific Firebase initialization
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyB8wTJe_xaQA7ZeDhAyPISjvNgwnOo9w4A",
          authDomain: "smart-waste-management-s-b1a36.firebaseapp.com",
          projectId: "smart-waste-management-s-b1a36",
          storageBucket: "smart-waste-management-s-b1a36.appspot.com",
          messagingSenderId: "975854822446",
          appId: "1:975854822446:web:3c5f58ec502bcf93fb6bbf",
          measurementId: "G-SWE3EYX58Z"),
    );
  } else {
    // Mobile-specific Firebase initialization
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Waste Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/add-bin': (context) => AddBinScreen(),
        '/requests': (context) => ViewRequestsScreen(),
        '/userHome': (context) => UserHomeScreen(),
        '/wasteCollectorHome': (context) => WasteCollectorScreen(),
      },
    );
  }
}
