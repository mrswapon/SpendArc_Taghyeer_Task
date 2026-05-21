// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:spend_arc/features/transactions/domain/usecases/add_transaction.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late AddTransaction usecase;
  late MockTransactionRepository mockRepo;

  final tTransaction = Transaction(
    id: 'test-1',
    title: 'Coffee',
    amount: 4.50,
    date: DateTime(2024, 6, 1),
    category: 'Food',
    type: TransactionType.expense,
  );

  setUp(() {
    mockRepo = MockTransactionRepository();
    usecase = AddTransaction(mockRepo);
  });

  // Test 1: Returns Right(transaction) on success.
  test('returns Right(transaction) when repository succeeds', () async {
    when(() => mockRepo.addTransaction(tTransaction))
        .thenAnswer((_) async => Right(tTransaction));

    final result = await usecase(AddTransactionParams(tTransaction));

    expect(result, Right<Failure, Transaction>(tTransaction));
    verify(() => mockRepo.addTransaction(tTransaction)).called(1);
    verifyNoMoreInteractions(mockRepo);
  });

  // Test 2: Returns Left(ServerFailure) when repository fails.
  test('returns Left(ServerFailure) when repository throws', () async {
    when(() => mockRepo.addTransaction(tTransaction))
        .thenAnswer((_) async => const Left(ServerFailure('Server error')));

    final result = await usecase(AddTransactionParams(tTransaction));

    expect(result, const Left<Failure, Transaction>(ServerFailure('Server error')));
    verify(() => mockRepo.addTransaction(tTransaction)).called(1);
    verifyNoMoreInteractions(mockRepo);
  });
}
