// Test 6: ArcMeterWidget renders with correct semantics for accessibility.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_arc/features/transactions/presentation/widgets/arc_meter_widget.dart';

void main() {
  testWidgets(
      'ArcMeterWidget has Semantics label describing budget usage percentage',
      (WidgetTester tester) async {
    const percentage = 0.65;
    const budget = 5000.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcMeterWidget(
            percentage: percentage,
            spent: 3250.0,
            budget: budget,
            currency: 'USD',
          ),
        ),
      ),
    );

    // Let the animation controller tick at least one frame.
    await tester.pump();

    // Verify Semantics node exists with the expected label substring.
    expect(
      find.bySemanticsLabel(
        // The label contains "Budget usage" and the currency+budget amount.
        RegExp(r'Budget usage.*\d+.*percent'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ArcMeterWidget rebuilds when percentage changes',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcMeterWidget(
            percentage: 0.3,
            spent: 1500.0,
            budget: 5000.0,
          ),
        ),
      ),
    );
    await tester.pump();

    // Replace with a higher percentage.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcMeterWidget(
            percentage: 0.8,
            spent: 4000.0,
            budget: 5000.0,
          ),
        ),
      ),
    );
    await tester.pump();

    // Widget is still present and renders without errors.
    expect(find.byType(ArcMeterWidget), findsOneWidget);
  });
}
