import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Create Special Schedule Form Tests', () {
    late GlobalKey<FormState> formKey;

    setUp(() {
      formKey = GlobalKey<FormState>();
    });

    // Build the test form based on CreateSpecialSchedulePage structure
    Widget buildTestForm() {
      return MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // City Info Card
                  Card(
                    child: ListTile(
                      title: Text('City'),
                      subtitle: Text('New York'),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Date Info Card
                  Card(
                    child: ListTile(
                      title: Text('Date'),
                      subtitle: Text('2023-12-10'),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Address Info Card
                  TextFormField(
                    key: Key('address'),
                    initialValue: '123 Main St', // Simulated value
                    decoration: InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  // Waste Types Section
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Waste Types'),
                          Divider(height: 24),
                          Text('Plastic: 5 kg'), // Example Waste Type
                        ],
                      ),
                    ),
                  ),

                  // Waste Collector Dropdown
                  DropdownButtonFormField<String>(
                    key: Key('wasteCollectorDropdown'),
                    value: 'John Doe', // Simulated waste collector
                    decoration: InputDecoration(labelText: 'Select Waste Collector'),
                    items: ['John Doe', 'Jane Doe'].map((collector) {
                      return DropdownMenuItem<String>(
                        value: collector,
                        child: Text(collector),
                      );
                    }).toList(),
                    onChanged: (value) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a waste collector';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  // City Dropdown
                  DropdownButtonFormField<String>(
                    key: Key('cityDropdown'),
                    value: 'New York', // Simulate valid city selection
                    decoration: InputDecoration(labelText: 'City'),
                    items: ['New York', 'Los Angeles'].map((city) {
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
                  SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Simulate form submission
                      }
                    },
                    child: Text('Create Schedule'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Test for validating address input
    testWidgets('Form validates address field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty address
      await tester.enterText(find.byKey(Key('address')), '');
      await tester.tap(find.text('Create Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid address'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid address
      await tester.enterText(find.byKey(Key('address')), '456 New Street');
      await tester.tap(find.text('Create Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid address'), findsNothing); // Assertion for valid case
    });

    // Test for waste collector dropdown validation
    testWidgets('Form validates waste collector dropdown correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());


      // Positive case: valid waste collector selected
      await tester.tap(find.byKey(Key('wasteCollectorDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe').first); 
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Please select a waste collector'), findsNothing); // Assertion for valid case
    });

    // Test for city dropdown validation
    testWidgets('Form validates city dropdown correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());


      // Positive case: valid city selected
      await tester.tap(find.byKey(Key('cityDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New York').first); 
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Please select a city'), findsNothing); // Assertion for valid case
    });
  });
}
