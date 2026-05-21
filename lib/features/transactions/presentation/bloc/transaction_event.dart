import 'package:equatable/equatable.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {
  const LoadTransactionsEvent();
}

class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;
  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  const DeleteTransactionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SyncTransactionsEvent extends TransactionEvent {
  const SyncTransactionsEvent();
}
