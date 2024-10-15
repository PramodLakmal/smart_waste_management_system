import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Add Vehicle Form Tests', () {
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
                TextFormField(
                  key: Key('vehicleId'),
                  decoration: InputDecoration(labelText: 'Vehicle ID'),
                  initialValue: 'V123', // Simulate valid Vehicle ID input
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a vehicle ID';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: Key('driverName'),
                  decoration: InputDecoration(labelText: 'Driver Name'),
                  initialValue: 'John Doe', // Simulate valid Driver Name input
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter driver\'s name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: Key('status'),
                  decoration: InputDecoration(labelText: 'Vehicle Status'),
                  initialValue: 'Active', // Simulate valid status
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle status';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: Key('latitude'),
                  decoration: InputDecoration(labelText: 'Latitude'),
                  initialValue: '37.422', // Simulate valid latitude
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: Key('longitude'),
                  decoration: InputDecoration(labelText: 'Longitude'),
                  initialValue: '-122.084', // Simulate valid longitude
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Simulate form submission
                      ScaffoldMessenger.of(formKey.currentContext!).showSnackBar(
                        SnackBar(content: Text('Vehicle Added Successfully!')),
                      );
                    }
                  },
                  child: Text('Add Vehicle'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('Form validates Vehicle ID field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty Vehicle ID input
      await tester.enterText(find.byKey(Key('vehicleId')), '');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a vehicle ID'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid Vehicle ID input
      await tester.enterText(find.byKey(Key('vehicleId')), 'V123');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a vehicle ID'), findsNothing); // Assertion for valid case
    });

    testWidgets('Form validates Driver Name field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty Driver Name input
      await tester.enterText(find.byKey(Key('driverName')), '');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter driver\'s name'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid Driver Name input
      await tester.enterText(find.byKey(Key('driverName')), 'Jane Doe');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter driver\'s name'), findsNothing); // Assertion for valid case
    });

    testWidgets('Form validates Status field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty Status input
      await tester.enterText(find.byKey(Key('status')), '');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter vehicle status'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid Status input
      await tester.enterText(find.byKey(Key('status')), 'Active');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter vehicle status'), findsNothing); // Assertion for valid case
    });

    testWidgets('Form validates Latitude field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty Latitude input
      await tester.enterText(find.byKey(Key('latitude')), '');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsOneWidget); // Assertion for invalid case

      // Negative case: invalid Latitude input
      await tester.enterText(find.byKey(Key('latitude')), 'invalid');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid Latitude input
      await tester.enterText(find.byKey(Key('latitude')), '37.422');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsNothing); // Assertion for valid case
    });

    testWidgets('Form validates Longitude field correctly - positive and negative cases', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty Longitude input
      await tester.enterText(find.byKey(Key('longitude')), '');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsOneWidget); // Assertion for invalid case

      // Negative case: invalid Longitude input
      await tester.enterText(find.byKey(Key('longitude')), 'invalid');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsOneWidget); // Assertion for invalid case

      // Positive case: valid Longitude input
      await tester.enterText(find.byKey(Key('longitude')), '-122.084');
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsNothing); // Assertion for valid case
    });
  });
}
