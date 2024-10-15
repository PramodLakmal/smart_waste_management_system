import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart'; // If you're using a provider
import 'package:smart_waste_management_system/screens/auth/login_screen.dart';
import 'package:smart_waste_management_system/screens/home_screen.dart';
import 'package:smart_waste_management_system/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('Login Screen Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Provider<AuthService>.value(
          value: mockAuthService,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('Displays error message for invalid login', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Input invalid email and password
      await tester.enterText(find.byType(TextFormField).first, 'invalid@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

      // Set up the mock to return null (failed login)
      when(mockAuthService.signIn('invalid@example.com', 'wrongpassword')).thenAnswer((_) async => null);

      // Tap the login button
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Verify the error message is displayed
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('Navigates to user home on successful login', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Input valid email and password
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'correctpassword');

      // Set up the mock to return user data
      when(mockAuthService.signIn('user@example.com', 'correctpassword')).thenAnswer((_) async {
        return {'role': 'user'};
      });

      // Tap the login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(); // Allow for navigation

      // Verify that navigation occurred to userHome
      expect(find.byType(HomeScreen), findsOneWidget); // Replace with the actual UserHomeScreen widget
    });

    testWidgets('Displays error message for empty email', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Input empty email and valid password
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.enterText(find.byType(TextFormField).at(1), 'validpassword');

      // Tap the login button
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Check if the error message for email is shown
      expect(find.text('Please enter email'), findsOneWidget); // Ensure you implement this validation
    });

    testWidgets('Displays error message for empty password', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Input valid email and empty password
      await tester.enterText(find.byType(TextFormField).first, 'valid@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), '');

      // Tap the login button
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Check if the error message for password is shown
      expect(find.text('Please enter password'), findsOneWidget); // Ensure you implement this validation
    });
  });
}
