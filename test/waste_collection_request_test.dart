import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_management_system/screens/admin/bin_summary_screen.dart';

void main() {
  testWidgets('BinSummaryScreen displays static text', (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(
      MaterialApp(
        home: BinSummaryScreen(),  // Replace with a simple widget that shows text.
      ),
    );

    // Check if a specific text is displayed in the widget
    expect(find.text('Collected Waste Summary Report'), findsOneWidget);
  });
}
