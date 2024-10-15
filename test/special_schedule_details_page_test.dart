import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:smart_waste_management_system/screens/admin/special_schedule_details.dart';
import 'package:smart_waste_management_system/models/special_schedule_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockDocumentReference mockDocumentReference;
  late MockCollectionReference mockCollectionReference;
  late SpecialSchedule testSchedule;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockDocumentReference = MockDocumentReference();
    mockCollectionReference = MockCollectionReference();

    // Create a test schedule
    testSchedule = SpecialSchedule(
      id: 'special_schedule_001',
      address: '123 Test St.',
      city: 'Test City',
      wasteCollector: 'John Doe',
      scheduledDate: DateTime.now(),
      status: 'Scheduled',
      wasteTypes: [
        WasteType(type: 'Plastic', weight: 15),
        WasteType(type: 'Glass', weight: 8),
      ], requestId: '', wasteCollectorId: '',
    );

    // Correct mock setup: Ensure collection() returns a non-null CollectionReference
    when(mockFirestore.collection('specialschedule'))
        .thenReturn(mockCollectionReference); // No type casting here

    // Ensure doc() returns a valid MockDocumentReference
    when(mockCollectionReference.doc(testSchedule.id))
        .thenReturn(mockDocumentReference);
  });

  testWidgets('SpecialScheduleDetailsPage renders schedule correctly', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: SpecialScheduleDetailsPage(specialSchedule: testSchedule),
      ),
    );

    // Format the scheduledDate using the same method as the widget
    final formattedDate = DateFormat('yyyy-MM-dd – hh:mm a').format(testSchedule.scheduledDate);

    // Verify if the schedule details are displayed correctly
    expect(find.text(testSchedule.address), findsOneWidget);
    expect(find.text(testSchedule.city), findsOneWidget);
    expect(find.text(testSchedule.wasteCollector), findsOneWidget);
    expect(find.text(formattedDate), findsOneWidget); // Check formatted date
    expect(find.text(testSchedule.status), findsOneWidget);
    expect(find.text('Plastic - 15 kg'), findsOneWidget);
    expect(find.text('Glass - 8 kg'), findsOneWidget);
  });

  testWidgets('Delete Schedule functionality triggers Firestore delete', (WidgetTester tester) async {
    // Mock Firestore delete operation
    when(mockDocumentReference.delete()).thenAnswer((_) async {});

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: SpecialScheduleDetailsPage(specialSchedule: testSchedule),
      ),
    );

    // Tap on the delete button
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Tap the Delete button in the confirmation dialog
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify that the delete function was called on Firestore
    verify(mockDocumentReference.delete()).called(1);
  });

  testWidgets('Cancel delete does not trigger Firestore delete', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: SpecialScheduleDetailsPage(specialSchedule: testSchedule),
      ),
    );

    // Tap on the delete button
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Tap the Cancel button in the confirmation dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify that delete was not called
    verifyNever(mockDocumentReference.delete());
  });
}
