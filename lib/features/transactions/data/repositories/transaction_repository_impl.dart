import 'package:dartz/dartz.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/core/network/network_info.dart';
import 'package:spend_arc/core/sync/write_queue.dart';
import 'package:spend_arc/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:spend_arc/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:spend_arc/features/transactions/data/models/transaction_model.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final WriteQueueService writeQueue;

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.writeQueue,
  });

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      // Always return local data immediately (offline-first).
      final local = await localDataSource.getTransactions();
      return Right(local);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(
      Transaction transaction) async {
    final model = TransactionModel.fromTransaction(transaction);
    try {
      // Write to local cache immediately.
      final saved = await localDataSource.addTransaction(model);

      final isOnline = await networkInfo.isConnected;
      if (isOnline) {
        try {
          await remoteDataSource.addTransaction(model);
        } catch (_) {
          // Remote failed — enqueue for later replay.
          await _enqueueAdd(model);
        }
      } else {
        await _enqueueAdd(model);
      }
      return Right(saved);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deleteTransaction(String id) async {
    try {
      await localDataSource.deleteTransaction(id);

      final isOnline = await networkInfo.isConnected;
      if (isOnline) {
        try {
          await remoteDataSource.deleteTransaction(id);
        } catch (_) {
          await _enqueueDelete(id);
        }
      } else {
        await _enqueueDelete(id);
      }
      return Right(id);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
      Transaction transaction) async {
    final model = TransactionModel.fromTransaction(transaction);
    try {
      final saved = await localDataSource.updateTransaction(model);

      final isOnline = await networkInfo.isConnected;
      if (!isOnline) {
        await writeQueue.enqueue(PendingMutation(
          id: '${MutationType.update.name}_${model.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: MutationType.update,
          payload: model.toJson(),
          timestamp: DateTime.now(),
        ));
      }
      return Right(saved);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _enqueueAdd(TransactionModel model) async {
    await writeQueue.enqueue(PendingMutation(
      id: '${MutationType.add.name}_${model.id}',
      type: MutationType.add,
      payload: model.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _enqueueDelete(String id) async {
    await writeQueue.enqueue(PendingMutation(
      id: '${MutationType.delete.name}_$id',
      type: MutationType.delete,
      payload: {'id': id},
      timestamp: DateTime.now(),
    ));
  }
}
