import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E7D32),  // Dark Green
                  Color(0xFF4CAF50),  // Green
                  Color(0xFF81C784),  // Light Green
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.eco,
                              size: 64,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Smart Waste',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Management System',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            SizedBox(height: 32),
                            if (_errorMessage != null) ...[
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                prefixIcon: Icon(Icons.email, color: Color(0xFF4CAF50)),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: Icon(Icons.lock, color: Color(0xFF4CAF50)),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
  onPressed: () async {
    setState(() => _errorMessage = null);
    // Attempt to sign in and fetch user data
    Map<String, dynamic>? userData = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );
    
    if (userData != null) {
      // Get the role from the user data (defaults to 'user' if no role is found)
      String userRole = userData['role'] ?? 'user';
      
      // Determine which home screen to navigate to based on the user role
      String route;
      if (userRole == 'user') {
        route = '/userHome';
      } else if (userRole == 'admin') {
        route = '/home';
      } else if (userRole == 'wasteCollector') {
        route = '/wasteCollectorHome';
      } else {
        // Default fallback, assuming all other cases are treated as normal users
        route = '/userHome';
      }
      
      // Navigate to the determined route
      Navigator.pushReplacementNamed(context, route);
    } else {
      // If login failed, show an error message
      setState(() => _errorMessage = 'Invalid email or password');
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF2E7D32),
    padding: EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text(
    'Login',
    style: TextStyle(fontSize: 18),
  ),
),
                            SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
                              child: Text(
                                "Don't have an account? Sign Up",
                                style: TextStyle(color: Color(0xFF2E7D32)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}