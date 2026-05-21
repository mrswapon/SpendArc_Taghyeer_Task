import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spend_arc/core/usecases/usecase.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_state.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/add_transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/get_transactions.dart';
import 'package:spend_arc/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:spend_arc/features/transactions/presentation/bloc/transaction_state.dart';

export 'transaction_event.dart';
export 'transaction_state.dart';

// Internal event — private to this file, not exported.
class _BudgetUpdatedEvent extends TransactionEvent {
  final double budget;
  const _BudgetUpdatedEvent(this.budget);

  @override
  List<Object?> get props => [budget];
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final DeleteTransaction _deleteTransaction;
  final SettingsBloc _settingsBloc;

  // Inter-bloc stream subscription — must be cancelled in close().
  late final StreamSubscription<SettingsState> _settingsSubscription;

  double _currentBudget = 5000.0;

  TransactionBloc({
    required GetTransactions getTransactions,
    required AddTransaction addTransaction,
    required DeleteTransaction deleteTransaction,
    required SettingsBloc settingsBloc,
  })  : _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _deleteTransaction = deleteTransaction,
        _settingsBloc = settingsBloc,
        super(const TransactionInitial()) {
    // Seed current budget from SettingsBloc's current state.
    final currentSettings = _settingsBloc.state;
    if (currentSettings is SettingsLoaded) {
      _currentBudget = currentSettings.settings.monthlyBudget;
    }

    // Listen to future settings changes and propagate budget updates.
    _settingsSubscription = _settingsBloc.stream.listen((settingsState) {
      if (settingsState is SettingsLoaded) {
        _currentBudget = settingsState.settings.monthlyBudget;
        add(_BudgetUpdatedEvent(_currentBudget));
      }
    });

    on<LoadTransactionsEvent>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<DeleteTransactionEvent>(_onDelete);
    on<_BudgetUpdatedEvent>(_onBudgetUpdated);
  }

  Future<void> _onLoad(
      LoadTransactionsEvent event, Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());
    final result = await _getTransactions(const NoParams());
    result.fold(
      (failure) => emit(
          TransactionError(message: failure.message, transactions: const [])),
      (transactions) => emit(TransactionLoaded(
        transactions: transactions,
        monthlyBudget: _currentBudget,
      )),
    );
  }

  Future<void> _onAdd(
      AddTransactionEvent event, Emitter<TransactionState> emit) async {
    final currentState = state;
    final previousTransactions = currentState is TransactionLoaded
        ? currentState.transactions
        : <Transaction>[];

    // --- Optimistic update: reflect the new transaction immediately ---
    if (currentState is TransactionLoaded) {
      emit(currentState.copyWith(
        transactions: [event.transaction, ...currentState.transactions],
      ));
    }

    final result =
        await _addTransaction(AddTransactionParams(event.transaction));

    result.fold(
      (failure) {
        // Roll back to the snapshot taken before the optimistic update.
        emit(TransactionError(
          message: failure.message,
          transactions: previousTransactions,
        ));
      },
      (_) {
        // Optimistic state is already correct — no extra emit needed.
      },
    );
  }

  Future<void> _onDelete(
      DeleteTransactionEvent event, Emitter<TransactionState> emit) async {
    final currentState = state;
    final previousTransactions = currentState is TransactionLoaded
        ? currentState.transactions
        : <Transaction>[];

    if (currentState is TransactionLoaded) {
      emit(currentState.copyWith(
        transactions:
            currentState.transactions.where((t) => t.id != event.id).toList(),
      ));
    }

    final result =
        await _deleteTransaction(DeleteTransactionParams(event.id));

    result.fold(
      (failure) {
        emit(TransactionError(
          message: failure.message,
          transactions: previousTransactions,
        ));
      },
      (_) {},
    );
  }

  void _onBudgetUpdated(
      _BudgetUpdatedEvent event, Emitter<TransactionState> emit) {
    _currentBudget = event.budget;
    if (state is TransactionLoaded) {
      emit((state as TransactionLoaded).copyWith(monthlyBudget: event.budget));
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription.cancel();
    return super.close();
  }
}
