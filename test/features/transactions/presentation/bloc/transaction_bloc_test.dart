// ignore_for_file: lines_longer_than_80_chars

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/core/usecases/usecase.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_event.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_state.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/add_transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/get_transactions.dart';
import 'package:spend_arc/features/transactions/presentation/bloc/transaction_bloc.dart';

class MockGetTransactions extends Mock implements GetTransactions {}
class MockAddTransaction extends Mock implements AddTransaction {}
class MockDeleteTransaction extends Mock implements DeleteTransaction {}
class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockGetTransactions mockGet;
  late MockAddTransaction mockAdd;
  late MockDeleteTransaction mockDelete;
  late MockSettingsBloc mockSettingsBloc;

  final tTransaction = Transaction(
    id: 'test-1',
    title: 'Coffee',
    amount: 4.50,
    date: DateTime(2024, 6, 1),
    category: 'Food',
    type: TransactionType.expense,
  );

  final tTransactions = [tTransaction];

  setUp(() {
    mockGet = MockGetTransactions();
    mockAdd = MockAddTransaction();
    mockDelete = MockDeleteTransaction();
    mockSettingsBloc = MockSettingsBloc();

    // Default settings state — budget loaded.
    when(() => mockSettingsBloc.state)
        .thenReturn(const SettingsInitial());
    when(() => mockSettingsBloc.stream)
        .thenAnswer((_) => const Stream.empty());

    registerFallbackValue(const NoParams());
    registerFallbackValue(AddTransactionParams(tTransaction));
    registerFallbackValue(const DeleteTransactionParams(''));
  });

  TransactionBloc _bloc() => TransactionBloc(
        getTransactions: mockGet,
        addTransaction: mockAdd,
        deleteTransaction: mockDelete,
        settingsBloc: mockSettingsBloc,
      );

  // Test 3: Emits [Loading, Loaded] on LoadTransactionsEvent.
  blocTest<TransactionBloc, TransactionState>(
    'emits [TransactionLoading, TransactionLoaded] when LoadTransactionsEvent added',
    build: () {
      when(() => mockGet(any()))
          .thenAnswer((_) async => Right(tTransactions));
      return _bloc();
    },
    act: (bloc) => bloc.add(const LoadTransactionsEvent()),
    expect: () => [
      const TransactionLoading(),
      isA<TransactionLoaded>()
          .having((s) => s.transactions, 'transactions', tTransactions),
    ],
  );

  // Test 4: Rolls back optimistic update on failure.
  blocTest<TransactionBloc, TransactionState>(
    'rolls back optimistic add when repository returns Left(failure)',
    build: () {
      when(() => mockGet(any()))
          .thenAnswer((_) async => Right(tTransactions));
      when(() => mockAdd(any()))
          .thenAnswer((_) async => const Left(ServerFailure('Server down')));
      return _bloc();
    },
    seed: () => TransactionLoaded(
      transactions: tTransactions,
      monthlyBudget: 5000,
    ),
    act: (bloc) => bloc.add(AddTransactionEvent(
      Transaction(
        id: 'new-1',
        title: 'New tx',
        amount: 10,
        date: DateTime(2024, 6, 2),
        category: 'Food',
        type: TransactionType.expense,
      ),
    )),
    expect: () => [
      // 1. Optimistic state (new transaction prepended).
      isA<TransactionLoaded>().having(
        (s) => s.transactions.length,
        'length increases optimistically',
        2,
      ),
      // 2. Rolled back to error state with previous transactions.
      isA<TransactionError>()
          .having((s) => s.message, 'message', 'Server down')
          .having((s) => s.transactions, 'rolled-back txs', tTransactions),
    ],
  );
}
