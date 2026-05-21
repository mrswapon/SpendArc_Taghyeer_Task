// DOMAIN LAYER — no Flutter imports allowed

import 'package:dartz/dartz.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/core/usecases/usecase.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactions implements UseCase<List<Transaction>, NoParams> {
  final TransactionRepository repository;

  GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params) {
    return repository.getTransactions();
  }
}
