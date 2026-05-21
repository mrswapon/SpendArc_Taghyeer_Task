// DOMAIN LAYER — no Flutter imports allowed

import 'package:dartz/dartz.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, String>> deleteTransaction(String id);
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction);
}
