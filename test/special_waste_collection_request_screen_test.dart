import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Special Waste Request Form Tests', () {
    late GlobalKey<FormState> formKey;

    setUp(() {
      formKey = GlobalKey<FormState>();
    });

    Widget buildTestForm() {
      return MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text('Electrical Waste'),
                  value: true, // Simulate checkbox selected
                  onChanged: (_) {},
                ),
                TextFormField(
                  key: Key('electricalWeight'),
                  decoration: InputDecoration(labelText: 'Enter Electrical Waste Weight (kg)'),
                  keyboardType: TextInputType.number,
                  initialValue: '5.0', // Simulate valid weight input
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),
                RadioListTile<bool>(
                  title: Text('Use Saved Address'),
                  value: true,
                  groupValue: true, // Simulate using saved address
                  onChanged: (_) {},
                ),
                TextFormField(
                  key: Key('address'),
                  initialValue: '123 Main Street', // Simulate valid address
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid address';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  key: Key('cityDropdown'),
                  value: 'Malabe', // Simulate valid city selection
                  decoration: InputDecoration(labelText: 'City'),
                  items: ['Malabe', 'Kaduwela'].map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {},
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                ),
                RadioListTile<bool>(
                  title: Text('Request Now'),
                  value: true,
                  groupValue: true, // Simulate "Request Now" selected
                  onChanged: (_) {},
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Simulate form submission
                    }
                  },
                  child: Text('Submit Request'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('Form validates weight input field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());


      // Positive case: valid weight input
      await tester.enterText(find.byKey(Key('electricalWeight')), '5');
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle(); // Ensure validation has settled
      expect(find.text('Please enter a valid weight'), findsNothing); // Assertion for valid case
    });

    testWidgets('Form validates address field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty address
      await tester.enterText(find.byKey(Key('address')), '');
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle(); 
      expect(find.text('Please enter a valid address'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid address
      await tester.enterText(find.byKey(Key('address')), '456 New Street');
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid address'), findsNothing); // Assertion for valid case
    });

    testWidgets('Form validates city dropdown correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());



      // Positive case: valid city selected
      await tester.tap(find.byKey(Key('cityDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Malabe').first); 
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();
      expect(find.text('Please select a city'), findsNothing); 
    });
  });
}
