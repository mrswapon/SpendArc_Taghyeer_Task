import 'package:equatable/equatable.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final double monthlyBudget;
  final bool isSyncing;

  const TransactionLoaded({
    required this.transactions,
    required this.monthlyBudget,
    this.isSyncing = false,
  });

  TransactionLoaded copyWith({
    List<Transaction>? transactions,
    double? monthlyBudget,
    bool? isSyncing,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get budgetUsageRatio =>
      monthlyBudget > 0 ? (totalExpenses / monthlyBudget).clamp(0.0, 1.0) : 0;

  List<double> get last7DaysSpending => _last7DaysByType(TransactionType.expense);

  List<double> get last7DaysIncome => _last7DaysByType(TransactionType.income);

  List<double> _last7DaysByType(TransactionType type) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return transactions
          .where((t) =>
              t.type == type &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
    });
  }

  @override
  List<Object?> get props => [transactions, monthlyBudget, isSyncing];
}

class TransactionError extends TransactionState {
  final String message;
  final List<Transaction> transactions;

  const TransactionError({
    required this.message,
    required this.transactions,
  });

  @override
  List<Object?> get props => [message, transactions];
}
