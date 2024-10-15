import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_waste_management_system/screens/user/cardDetails.dart';


void main() {
  group('Add Card Details Form Tests', () {
    late GlobalKey<FormState> formKey;

    setUp(() {
      formKey = GlobalKey<FormState>();
    });

    Widget buildTestForm() {
      return MaterialApp(
        home: Scaffold(
          body: AddCardDetails(),
        ),
      );
    }

    testWidgets('Form validates cardholder name field correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty cardholder name
      await tester.enterText(find.byType(TextFormField).first, ''); // First field is cardholder name
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Please enter cardholder name'), findsOneWidget);

      // Positive case: valid cardholder name
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Please enter cardholder name'), findsNothing);
    });

    testWidgets('Form validates card number field correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty card number
      await tester.enterText(find.byType(TextFormField).at(1), ''); // Second field is card number
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Please enter card number'), findsOneWidget);

      // Negative case: invalid card number
      await tester.enterText(find.byType(TextFormField).at(1), '123456'); // Invalid card number
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Invalid card number'), findsOneWidget);

      // Positive case: valid card number
      await tester.enterText(find.byType(TextFormField).at(1), '4111111111111111'); // Valid Visa card number
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Invalid card number'), findsNothing);
    });

    testWidgets('Form validates expiry date field correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty expiry date
      await tester.enterText(find.byType(TextFormField).at(2), ''); // Third field is expiry date
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Please enter expiry date'), findsOneWidget);

      // Negative case: invalid expiry date format
      await tester.enterText(find.byType(TextFormField).at(2), '1234'); // Invalid format
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Enter a valid date (MM/YY)'), findsOneWidget);

      // Positive case: valid expiry date
      await tester.enterText(find.byType(TextFormField).at(2), '12/25'); // Valid format
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Enter a valid date (MM/YY)'), findsNothing);
    });

    testWidgets('Form validates CVV field correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestForm());

      // Negative case: empty CVV
      await tester.enterText(find.byType(TextFormField).last, ''); // Last field is CVV
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('Please enter CVV'), findsOneWidget);

      // Negative case: invalid CVV length
      await tester.enterText(find.byType(TextFormField).last, '12'); // Invalid length
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('CVV must be 3 digits'), findsOneWidget);

      // Positive case: valid CVV
      await tester.enterText(find.byType(TextFormField).last, '123'); // Valid CVV
      await tester.tap(find.text('Save Card Details'));
      await tester.pump();
      expect(find.text('CVV must be 3 digits'), findsNothing);
    });
  });
}
