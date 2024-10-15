// completed_schedules_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_waste_management_system/screens/admin/completed_speacial_schedules.dart';

// Create mock classes for FirebaseAuth and FirebaseFirestore
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('CompletedSchedulesPage Tests', () {
    // Variables for the mock classes
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestore = MockFirebaseFirestore();
    });

    testWidgets('Displays "Please log in first" when no user is logged in', (WidgetTester tester) async {
      // Arrange: Setup the mock auth with no current user
      when(mockAuth.currentUser).thenReturn(null);

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: CompletedSchedulesPage(),
        ),
      );

      // Assert: Verify that the appropriate message is displayed
      expect(find.text('Please log in first'), findsOneWidget);
    });

    testWidgets('Shows loading indicator while fetching data', (WidgetTester tester) async {
      // Arrange: Setup mock auth with a signed-in user
      when(mockUser.uid).thenReturn('user123');
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Setup Firestore mock to return a Stream with no data
      final mockStream = Stream<QuerySnapshot<Map<String, dynamic>>>.fromIterable([MockQuerySnapshot()]);
      when(mockFirestore.collection('specialschedule').where('wasteCollectorId', isEqualTo: anyNamed('isEqualTo')).snapshots())
          .thenAnswer((_) => mockStream as Stream<QuerySnapshot<Map<String, dynamic>>>);

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: CompletedSchedulesPage(),
        ),
      );

      // Assert: Check if CircularProgressIndicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays "No completed schedules found" when there is no data', (WidgetTester tester) async {
      // Arrange: Setup mock auth with a signed-in user
      when(mockUser.uid).thenReturn('user123');
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Setup Firestore mock to return an empty QuerySnapshot
      final mockQuerySnapshot = MockQuerySnapshot();
      when(mockQuerySnapshot.docs).thenReturn([]);
      final mockStream = Stream<QuerySnapshot>.fromIterable([mockQuerySnapshot]);
      when(mockFirestore.collection('specialschedule').where('wasteCollectorId', isEqualTo: anyNamed('wasteCollectorId')).snapshots())
          .thenAnswer((_) => mockStream as Stream<QuerySnapshot<Map<String, dynamic>>>);

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: CompletedSchedulesPage(),
        ),
      );

      // Let the StreamBuilder receive the data
      await tester.pumpAndSettle();

      // Assert: Verify that "No completed schedules found." is displayed
      expect(find.text('No completed schedules found.'), findsOneWidget);
    });

    testWidgets('Displays completed schedules when data exists', (WidgetTester tester) async {
      // Arrange: Setup mock auth with a signed-in user
      when(mockUser.uid).thenReturn('user123');
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Setup Firestore mock to return a populated QuerySnapshot
      final mockDocumentSnapshot = MockDocumentSnapshot();
      when(mockDocumentSnapshot.data()).thenReturn({
        'wasteCollectorId': 'user123',
        'status': 'completed',
        'scheduledDate': Timestamp.fromDate(DateTime(2024, 10, 10)),
        'wasteTypes': [
          {'type': 'Plastic', 'weight': 5.0},
        ],
      });

      final mockQuerySnapshot = MockQuerySnapshot();
      when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
      final mockStream = Stream<QuerySnapshot>.fromIterable([mockQuerySnapshot]);
      when(mockFirestore.collection('specialschedule').where('wasteCollectorId', isEqualTo: anyNamed('isEqualTo')).snapshots())
          .thenAnswer((_) => mockStream as Stream<QuerySnapshot<Map<String, dynamic>>>);

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: CompletedSchedulesPage(),
        ),
      );

      // Let the StreamBuilder receive the data
      await tester.pumpAndSettle();

      // Assert: Verify that the schedule details are displayed
      expect(find.text('Schedule #1'), findsOneWidget);
      expect(find.text('Plastic:'), findsOneWidget);
      expect(find.text('5.0 kg'), findsOneWidget);
    });
  });
}
