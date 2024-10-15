import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A simple form widget for testing
  Widget createTestableWidget() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                key: ValueKey('nameField'),
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              TextFormField(
                key: ValueKey('emailField'),
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              TextFormField(
                key: ValueKey('passwordField'),
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                key: ValueKey('submitButton'),
                onPressed: () {
                  // Trigger form validation
                  if (formKey.currentState!.validate()) {
                    // Form is valid, handle success (e.g., show a success message)
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('Form Validation Tests', () {
    testWidgets('Name field should not be empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());

      final nameField = find.byKey(ValueKey('nameField'));
      final submitButton = find.byKey(ValueKey('submitButton'));

      // Enter an empty name.
      await tester.enterText(nameField, '');
      await tester.tap(submitButton);
      await tester.pump();

      // Verify that an error message is displayed.
      expect(find.text('Name cannot be empty'), findsOneWidget);
    });

    testWidgets('Email field should have valid format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());

      final emailField = find.byKey(ValueKey('emailField'));
      final submitButton = find.byKey(ValueKey('submitButton'));

      // Enter an invalid email.
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(submitButton);
      await tester.pump();

      // Verify that an error message is displayed.
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Password field should have minimum length', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());

      final passwordField = find.byKey(ValueKey('passwordField'));
      final submitButton = find.byKey(ValueKey('submitButton'));

      // Enter a short password.
      await tester.enterText(passwordField, '123');
      await tester.tap(submitButton);
      await tester.pump();

      // Verify that an error message is displayed.
      expect(find.text('Password must be at least 6 characters long'), findsOneWidget);
    });

    testWidgets('Valid input should submit the form', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());

      final nameField = find.byKey(ValueKey('nameField'));
      final emailField = find.byKey(ValueKey('emailField'));
      final passwordField = find.byKey(ValueKey('passwordField'));
      final submitButton = find.byKey(ValueKey('submitButton'));

      // Enter valid details.
      await tester.enterText(nameField, 'John Doe');
      await tester.enterText(emailField, 'john@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(submitButton);
      await tester.pump();

      // Verify that no error messages are displayed.
      expect(find.text('Name cannot be empty'), findsNothing);
      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.text('Password must be at least 6 characters long'), findsNothing);
    });
  });
}
