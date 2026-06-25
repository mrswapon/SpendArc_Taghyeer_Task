import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_arc/features/transactions/presentation/widgets/line_chart_widget.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 220,
          width: 400,
          child: child,
        ),
      ),
    );
  }

  group('LineChartWidget', () {
    testWidgets('renders fl_chart with income and expense data', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LineChartWidget(
            expenseData: [10, 20, 15, 30, 25, 40, 35],
            incomeData: [50, 60, 55, 70, 65, 80, 75],
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No chart data yet'), findsNothing);
    });

    testWidgets('renders when all values are zero', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LineChartWidget(
            expenseData: [0, 0, 0, 0, 0, 0, 0],
            incomeData: [0, 0, 0, 0, 0, 0, 0],
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows empty state with empty data lists', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LineChartWidget(
            expenseData: [],
            incomeData: [],
            labels: [],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsNothing);
      expect(find.text('No chart data yet'), findsOneWidget);
    });

    testWidgets('renders with single data point', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LineChartWidget(
            expenseData: [100],
            incomeData: [200],
            labels: ['Mon'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders both income and expense line bars', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LineChartWidget(
            expenseData: [10, 20, 30],
            incomeData: [40, 50, 60],
            labels: ['Mon', 'Tue', 'Wed'],
          ),
        ),
      );
      await tester.pump();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.lineBarsData.length, 2);
      expect(lineChart.data.lineBarsData[0].spots.length, 3);
      expect(lineChart.data.lineBarsData[1].spots.length, 3);
    });
  });
}
