import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/screens/admin/schedule_details.dart';
import 'package:smart_waste_management_system/models/schedule_model.dart';
import 'package:smart_waste_management_system/screens/admin/update_schedule.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockDocumentReference extends Mock implements DocumentReference {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockDocumentReference mockDocumentReference;
  late Schedule testSchedule;

  setUp(() {
    // Initialize mock objects
    mockFirestore = MockFirebaseFirestore();
    mockDocumentReference = MockDocumentReference();

    // Create a test schedule
    testSchedule = Schedule(
      id: 'schedule_001',
      city: 'City A',
      wasteCollector: 'John Doe',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 2)),
      wasteCollectorId: '',
    );
  });

testWidgets('ScheduleDetailsPage renders schedule correctly', (WidgetTester tester) async {
  // Build the widget
  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleDetailsPage(schedule: testSchedule),
    ),
  );

  // Format the start and end time using the same method as in the widget
  final formattedStartTime = DateFormat('yyyy-MM-dd – hh:mm a').format(testSchedule.startTime);
  final formattedEndTime = DateFormat('yyyy-MM-dd – hh:mm a').format(testSchedule.endTime);

  // Verify if the schedule details are displayed correctly
  expect(find.text(testSchedule.city), findsOneWidget);
  expect(find.text(testSchedule.wasteCollector), findsOneWidget);
  expect(find.text(formattedStartTime), findsOneWidget);  // Check formatted start time
  expect(find.text(formattedEndTime), findsOneWidget);    // Check formatted end time
});


  testWidgets('FormatDateTime method formats date correctly', (WidgetTester tester) async {
    final scheduleDetailsPage = ScheduleDetailsPage(schedule: testSchedule);

    // Check if the formatDateTime method works as expected
    String formattedDate = scheduleDetailsPage.formatDateTime(testSchedule.startTime);
    expect(formattedDate, contains(testSchedule.startTime.year.toString()));
  });

  testWidgets('Delete Schedule functionality triggers Firebase delete', (WidgetTester tester) async {
    // Mock the Firestore delete call
    when(mockFirestore.collection('schedules').doc(testSchedule.id).delete()).thenAnswer((_) async {});

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleDetailsPage(schedule: testSchedule),
      ),
    );

    // Tap on the delete button
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Show confirmation dialog and confirm deletion
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify Firestore delete was called
    verify(mockFirestore.collection('schedules').doc(testSchedule.id).delete()).called(1);
  });

  testWidgets('Edit button navigates to UpdateSchedulePage', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleDetailsPage(schedule: testSchedule),
      ),
    );

    // Tap the Edit button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();  // Ensure all animations and navigation settle

    // Verify that the UpdateSchedulePage is pushed to the navigator
    expect(find.byType(UpdateSchedulePage), findsOneWidget);
  });
}
