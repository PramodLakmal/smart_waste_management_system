import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/screens/admin/add_vehicle_form.dart';

// Mock Firestore class
class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('AddVehicleForm Tests', () {
    // Mock Firestore instance
    late MockFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirestore();
    });

    testWidgets('validates empty form fields', (WidgetTester tester) async {
      //await tester.pumpWidget(MaterialApp(home: Scaffold(body: AddVehicleForm(firestore: mockFirestore))));

      // Tap the 'Add Vehicle' button without entering data
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();

      // Expect validation errors
      expect(find.text('Please enter a vehicle ID'), findsOneWidget);
      expect(find.text('Please enter driver\'s name'), findsOneWidget);
      expect(find.text('Please enter vehicle status'), findsOneWidget);
      expect(find.text('Please enter a valid number'), findsNWidgets(2)); // Latitude and Longitude
    });

    testWidgets('adds a vehicle on valid input', (WidgetTester tester) async {
      // Build the widget
      //await tester.pumpWidget(MaterialApp(home: Scaffold(body: AddVehicleForm(firestore: mockFirestore))));

      // Enter valid input in form fields
      await tester.enterText(find.byKey(Key('vehicleIdField')), '12345');
      await tester.enterText(find.byKey(Key('driverNameField')), 'John Doe');
      await tester.enterText(find.byKey(Key('statusField')), 'Active');
      await tester.enterText(find.byKey(Key('latitudeField')), '22');
      await tester.enterText(find.byKey(Key('longitudeField')), '11');

      // Tap the 'Add Vehicle' button
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();

      // Verify Firestore method was called with the correct data
      verify(mockFirestore.collection('vehicleTracking').doc('12345').set({
        'vehicleId': '12345',
        'driverName': 'John Doe',
        'status': 'Active',
        'location': GeoPoint(51.5074, 0.1278),
      })).called(1);

      // Verify success message is shown
      expect(find.text('Vehicle Added Successfully!'), findsOneWidget);
    });

    testWidgets('displays error message on Firestore failure', (WidgetTester tester) async {
      // Set up Firestore to throw an error
      when(mockFirestore.collection('vehicleTracking').doc(any).set(any as Map<String, dynamic>))
          .thenThrow(Exception('Firestore error'));

      //await tester.pumpWidget(MaterialApp(home: Scaffold(body: AddVehicleForm(firestore: mockFirestore))));

      // Enter valid input in form fields
      await tester.enterText(find.byKey(Key('vehicleIdField')), '12345');
      await tester.enterText(find.byKey(Key('driverNameField')), 'John Doe');
      await tester.enterText(find.byKey(Key('statusField')), 'Active');
      await tester.enterText(find.byKey(Key('latitudeField')), '51.5074');
      await tester.enterText(find.byKey(Key('longitudeField')), '0.1278');

      // Tap the 'Add Vehicle' button
      await tester.tap(find.text('Add Vehicle'));
      await tester.pump();

      // Verify error message is shown
      expect(find.text('Failed to add vehicle. Please try again.'), findsOneWidget);
    });
  });
}
