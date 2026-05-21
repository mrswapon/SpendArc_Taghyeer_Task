import 'package:hive_flutter/hive_flutter.dart';
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/features/transactions/data/models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> addTransaction(TransactionModel model);
  Future<String> deleteTransaction(String id);
  Future<TransactionModel> updateTransaction(TransactionModel model);
  Future<void> saveAll(List<TransactionModel> models);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  static const String _boxName = 'transactions';
  final Box<TransactionModel> _box;

  TransactionLocalDataSourceImpl(this._box);

  static Future<TransactionLocalDataSourceImpl> create() async {
    final box = await Hive.openBox<TransactionModel>(_boxName);
    return TransactionLocalDataSourceImpl(box);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final models = _box.values.toList();
    models.sort((a, b) => b.date.compareTo(a.date));
    return models;
  }

  @override
  Future<TransactionModel> addTransaction(TransactionModel model) async {
    await _box.put(model.id, model);
    return model;
  }

  @override
  Future<String> deleteTransaction(String id) async {
    if (!_box.containsKey(id)) {
      throw const CacheFailure('Transaction not found');
    }
    await _box.delete(id);
    return id;
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel model) async {
    await _box.put(model.id, model);
    return model;
  }

  @override
  Future<void> saveAll(List<TransactionModel> models) async {
    final map = <String, TransactionModel>{
      for (final m in models) m.id: m,
    };
    await _box.putAll(map);
  }
}
