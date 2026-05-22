import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spend_arc/core/error/failures.dart';
import 'package:spend_arc/features/transactions/data/models/transaction_model.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> addTransaction(TransactionModel model);
  Future<String> deleteTransaction(String id);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  TransactionRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'https://api.spendingarc.example.com',
  });

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/transactions'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
        return json
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ServerFailure('Failed to fetch transactions');
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TransactionModel> addTransaction(TransactionModel model) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/transactions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(model.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return model;
      }
      throw const ServerFailure('Failed to add transaction');
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<String> deleteTransaction(String id) async {
    try {
      final response = await client
          .delete(Uri.parse('$baseUrl/transactions/$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return id;
      }
      throw const ServerFailure('Failed to delete transaction');
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }
}

/// Mock remote datasource for development / demo purposes.
class MockTransactionRemoteDataSource implements TransactionRemoteDataSource {
  static final _seed = <TransactionModel>[
    TransactionModel(
      id: 'remote-1',
      title: 'Grocery Store',
      amount: 87.50,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Food',
      typeIndex: TransactionType.expense.index,
    ),
    TransactionModel(
      id: 'remote-2',
      title: 'Monthly Salary',
      amount: 4200.00,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Income',
      typeIndex: TransactionType.income.index,
    ),
    TransactionModel(
      id: 'remote-4',
      title: 'Freelance Project',
      amount: 850.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Income',
      typeIndex: TransactionType.income.index,
    ),
    TransactionModel(
      id: 'remote-3',
      title: 'Electric Bill',
      amount: 120.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Utilities',
      typeIndex: TransactionType.expense.index,
    ),
  ];

  @override
  Future<List<TransactionModel>> getTransactions() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.of(_seed);
  }

  @override
  Future<TransactionModel> addTransaction(TransactionModel model) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _seed.add(model);
    return model;
  }

  @override
  Future<String> deleteTransaction(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _seed.removeWhere((t) => t.id == id);
    return id;
  }
}
