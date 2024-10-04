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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InputField(controller: _emailController, hintText: 'Email'),
            InputField(controller: _passwordController, hintText: 'Password', obscureText: true),
            CustomButton(
              text: 'Login',
              onPressed: () async {
                await _authService.signIn(
                  _emailController.text,
                  _passwordController.text,
                );
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            SizedBox(height: 20), // Add space between buttons
            TextButton(
              onPressed: () {
                // Navigate to Sign-Up screen
                Navigator.pushNamed(context, '/signup');
              },
              child: Text(
                "Don't have an account? Sign Up",
                style: TextStyle(color: Colors.blue), // Change color to your preference
              ),
            ),
          ],
        ),
      ),
    );
  }
}
