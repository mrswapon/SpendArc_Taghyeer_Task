// DOMAIN LAYER — no Flutter imports allowed

import 'package:dartz/dartz.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/core/usecases/usecase.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransactionParams {
  final Transaction transaction;
  const AddTransactionParams(this.transaction);
}

class AddTransaction implements UseCase<Transaction, AddTransactionParams> {
  final TransactionRepository repository;

  AddTransaction(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(AddTransactionParams params) {
    return repository.addTransaction(params.transaction);
  }
}
