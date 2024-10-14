import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_management_system/screens/auth/signup_screen.dart';

class TestsingUp extends StatefulWidget {
  const TestsingUp({super.key});

  @override
  State<TestsingUp> createState() => _TestsingUpState();
}

class _TestsingUpState extends State<TestsingUp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignUpScreen(), // Use your SignUpScreen widget here
    );
  }
}

void main() {
  testWidgets('Sign Up screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const TestsingUp());

    // Verify that the sign-up form is displayed
    expect(find.text('Join Smart Waste'), findsOneWidget);
    expect(find.byType(TextFormField),
        findsNWidgets(3)); // Name, email, and password fields
    expect(find.text('Sign Up'), findsOneWidget);

    // Enter invalid email and password
    await tester.enterText(find.byType(TextFormField).at(0), ''); // Name
    await tester.enterText(
        find.byType(TextFormField).at(1), 'invalidemail'); // Email
    await tester.enterText(find.byType(TextFormField).at(2), '123'); // Password

    // Tap the sign-up button
    await tester.tap(find.text('Sign Up'));
    await tester.pump(); // Trigger a frame to process the tap

    // Verify that the validation messages are displayed
    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter a valid email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters long'),
        findsOneWidget);

    // Now enter valid details
    await tester.enterText(
        find.byType(TextFormField).at(0), 'John Doe'); // Name
    await tester.enterText(
        find.byType(TextFormField).at(1), 'john@example.com'); // Email
    await tester.enterText(
        find.byType(TextFormField).at(2), 'password123'); // Password

    // Tap the sign-up button again
    await tester.tap(find.text('Sign Up'));
    await tester.pump(); // Trigger a frame to process the tap

    // Verify that the user is navigated to the home screen
    // Assuming you have a route named '/userHome' for successful sign-up
    expect(find.text('User Home'),
        findsOneWidget); // Replace 'User Home' with an expected text or widget in the home screen
  });
}
