import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_waste_management_system/screens/admin/completed_speacial_schedules.dart';

// Create Mock Classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQuery extends Mock implements Query {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockCollectionReference mockCollectionReference;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockCollectionReference = MockCollectionReference();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: CompletedSchedulesPage(
        auth: mockAuth,
        firestore: mockFirestore,
      ),
    );
  }

  group('CompletedSchedulesPage', () {
    testWidgets('shows login prompt when user is not logged in', (WidgetTester tester) async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Please log in first'), findsOneWidget);
    });

    testWidgets('shows no completed schedules message', (WidgetTester tester) async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockFirestore.collection('specialschedule')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.where('status', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockCollectionReference);
      when(mockCollectionReference.snapshots()).thenAnswer((_) => Stream.value(MockQuerySnapshot() as QuerySnapshot<Map<String, dynamic>>));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('No completed schedules found.'), findsOneWidget);
    });

    testWidgets('displays completed schedules and total waste collected', (WidgetTester tester) async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockFirestore.collection('specialschedule')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.where('status', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockCollectionReference);

      // Create a mock snapshot with sample data
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocumentSnapshot = MockDocumentSnapshot();
      when(mockDocumentSnapshot.data()).thenReturn({
        'scheduledDate': Timestamp.now(),
        'status': 'completed',
        'wasteTypes': [
          {'type': 'Plastic', 'weight': 2.5},
          {'type': 'Organic', 'weight': 3.0},
        ],
      });

      // Set up mock to return a list of documents
      when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot as QueryDocumentSnapshot<Map<String, dynamic>>]);
      when(mockCollectionReference.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot as QuerySnapshot<Map<String, dynamic>>));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Allow time for the stream to update

      // Assert
      expect(find.text('Total Waste Collected:  5.50 kg'), findsOneWidget);
      expect(find.text('Schedule #1'), findsOneWidget);
      expect(find.text('Waste Types:'), findsOneWidget);
      expect(find.text('Plastic:'), findsOneWidget);
      expect(find.text('Organic:'), findsOneWidget);
    });
  });
}
