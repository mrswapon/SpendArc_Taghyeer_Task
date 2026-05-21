import 'package:hive_flutter/hive_flutter.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';

part 'transaction_model.g.dart';

// TransactionModel stores typeIndex as int to avoid a custom enum adapter.
@HiveType(typeId: 0)
class TransactionModel extends Transaction {
  final int typeIndex;

  TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.category,
    required this.typeIndex,
  }) : super(type: TransactionType.values[typeIndex]);

  factory TransactionModel.fromTransaction(Transaction t) => TransactionModel(
        id: t.id,
        title: t.title,
        amount: t.amount,
        date: t.date,
        category: t.category,
        typeIndex: t.type.index,
      );

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        category: json['category'] as String,
        typeIndex: json['typeIndex'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'category': category,
        'typeIndex': typeIndex,
      };
}
