// DOMAIN LAYER — no Flutter imports allowed

import 'package:dartz/dartz.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/core/usecases/usecase.dart';
import 'package:spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransactionParams {
  final String id;
  const DeleteTransactionParams(this.id);
}

class DeleteTransaction implements UseCase<String, DeleteTransactionParams> {
  final TransactionRepository repository;

  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, String>> call(DeleteTransactionParams params) {
    return repository.deleteTransaction(params.id);
  }
}
