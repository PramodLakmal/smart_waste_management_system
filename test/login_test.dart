import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_management_system/screens/auth/login_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_waste_management_system/screens/home_screen.dart';
import 'package:smart_waste_management_system/services/auth_service.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class LoginTest extends StatelessWidget {
  final AuthService authService;

  const LoginTest({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(), // No need to pass AuthService directly
    );
  }
}

void main() {
  testWidgets('Login screen test with invalid credentials', (WidgetTester tester) async {
    // Initialize the mock AuthService
    final mockAuthService = MockAuthService();

    // Set up the LoginScreen to use the mock AuthService
    when(mockAuthService.signIn(any as String, any as String)).thenAnswer((_) async => {'error': 'Invalid email or password'}); // Simulating failed login

    await tester.pumpWidget(LoginTest(authService: mockAuthService));

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
  });

  testWidgets('Login screen test with valid credentials', (WidgetTester tester) async {
    // Initialize the mock AuthService
    final mockAuthService = MockAuthService();

    // Simulate successful login
    when(mockAuthService.signIn(any as String, any as String)).thenAnswer((_) async => {
      'role': 'user', // Simulate user role returned from authentication
    });

    await tester.pumpWidget(LoginTest(authService: mockAuthService));

    // Verify that the login form is displayed
    expect(find.text('Smart Waste'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    expect(find.text('Login'), findsOneWidget);

    // Enter valid email and password
    await tester.enterText(find.byType(TextFormField).at(0), 'valid@email.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'correctpassword');

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(); // Wait for navigation to complete

    // Verify that the navigation occurred (check for expected routes)
    expect(find.byType(HomeScreen), findsOneWidget); // Replace with the actual home page widget you expect
  });
}
