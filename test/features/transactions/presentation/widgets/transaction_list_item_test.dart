// Test 7: Swipe-to-delete dismisses the item and calls onDelete callback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/presentation/widgets/transaction_list_item.dart';

void main() {
  final tTransaction = Transaction(
    id: 'widget-test-1',
    title: 'Test Transaction',
    amount: 25.0,
    date: DateTime(2024, 6, 1),
    category: 'Food',
    type: TransactionType.expense,
  );

  testWidgets('TransactionListItem renders title and amount',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionListItem(transaction: tTransaction),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Test Transaction'), findsOneWidget);
    expect(find.textContaining('25.00'), findsOneWidget);
  });

  // Test 7: Swiping left past the threshold triggers onDelete.
  testWidgets('swipe left past threshold calls onDelete callback',
      (WidgetTester tester) async {
    bool deleteCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: TransactionListItem(
              transaction: tTransaction,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final itemFinder = find.byType(TransactionListItem);
    expect(itemFinder, findsOneWidget);

    // Simulate a fast leftward drag past the delete threshold (>100 px
    // or velocity < -1200 px/s — we use a long drag).
    await tester.drag(itemFinder, const Offset(-300, 0));
    // Run all animations to completion.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(deleteCalled, isTrue);
  });
}
