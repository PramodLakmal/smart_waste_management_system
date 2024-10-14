import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_management_system/screens/auth/login_screen.dart';


class LoginTest extends StatefulWidget {
  const LoginTest({super.key});

  @override
  State<LoginTest> createState() => _LoginTestState();
}

class _LoginTestState extends State<LoginTest> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(), // Use your LoginScreen widget here
    );
  }
}

void main() {
  testWidgets('Login screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const LoginTest());

    // Verify that the login form is displayed
    expect(find.text('Smart Waste'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    expect(find.text('Login'), findsOneWidget);

    // Enter invalid email and password
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid@email.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pump(); // Trigger a frame to process the tap

    // Verify that the error message is displayed
    expect(find.text('Invalid email or password'), findsOneWidget);

    // You can also test navigation for a valid login case.
    // You might want to mock the AuthService for this.
  });
}
