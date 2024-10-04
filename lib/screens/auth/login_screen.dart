import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage; // Store error message

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double formWidth = screenWidth > 600 ? 500 : double.infinity; // Make form narrower for larger screens

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display error message if exists
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16), // Space before input fields
                    ],

                    // Email input field
                    InputField(
                      controller: _emailController,
                      hintText: 'Email',
                    ),
                    SizedBox(height: 16), // Add space between fields

                    // Password input field
                    InputField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    SizedBox(height: 24), // Add space between fields

                    // Login button
                    CustomButton(
                      text: 'Login',
                      onPressed: () async {
                        // Reset the error message
                        setState(() {
                          _errorMessage = null;
                        });

                        // Attempt to sign in
                        bool success = await _authService.signIn(
                          _emailController.text,
                          _passwordController.text,
                        );

                        // If login is successful, navigate to home, else show error
                        if (success) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          setState(() {
                            _errorMessage = 'Invalid email or password'; // Set error message
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20), // Add space between buttons

                    // Sign-up link
                    TextButton(
                      onPressed: () {
                        // Navigate to Sign-Up screen
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
