import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/custom_button.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust the form width based on screen size
          double screenWidth = constraints.maxWidth;
          double formWidth = screenWidth > 600 ? 500 : double.infinity; // Constrain form width on large screens

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Full Name input field
                    InputField(
                      controller: _nameController,
                      hintText: 'Full Name',
                    ),
                    SizedBox(height: 16), // Add space between fields

                    // Email input field
                    InputField(
                      controller: _emailController,
                      hintText: 'Email',
                    ),
                    SizedBox(height: 16),

                    // Password input field
                    InputField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    SizedBox(height: 16),

                    // Phone input field
                    InputField(
                      controller: _phoneController,
                      hintText: 'Phone',
                    ),
                    SizedBox(height: 24), // Add space before the button

                    // Sign Up button
                    CustomButton(
                      text: 'Sign Up',
                      onPressed: () async {
                        await _authService.signUp(
                          _emailController.text,
                          _passwordController.text,
                          _nameController.text,
                          _phoneController.text,
                        );
                        Navigator.pushReplacementNamed(context, '/home');
                      },
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
