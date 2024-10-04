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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputField(controller: _emailController, hintText: 'Email'),
            InputField(controller: _passwordController, hintText: 'Password', obscureText: true),
            InputField(controller: _nameController, hintText: 'Full Name'),
            InputField(controller: _phoneController, hintText: 'Phone'),
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
    );
  }
}
