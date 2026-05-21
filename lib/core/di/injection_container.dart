import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:spend_arc/core/network/network_info.dart';
import 'package:spend_arc/core/sync/sync_service.dart';
import 'package:spend_arc/core/sync/write_queue.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:spend_arc/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:spend_arc/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:spend_arc/features/transactions/data/models/transaction_model.dart';
import 'package:spend_arc/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:spend_arc/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:spend_arc/features/transactions/domain/usecases/add_transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:spend_arc/features/transactions/domain/usecases/get_transactions.dart';
import 'package:spend_arc/features/transactions/presentation/bloc/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Hive ────────────────────────────────────────────────────────────────────
  Hive.registerAdapter(TransactionModelAdapter());
  final txBox = await Hive.openBox<TransactionModel>('transactions');

  // ── External ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // ── Core ────────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<Connectivity>()));

  // ── Write queue ─────────────────────────────────────────────────────────────
  final writeQueue = WriteQueueService();
  await writeQueue.init();
  sl.registerSingleton<WriteQueueService>(writeQueue);

  // ── Data sources ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionLocalDataSource>(
      () => TransactionLocalDataSourceImpl(txBox));

  sl.registerLazySingleton<TransactionRemoteDataSource>(
      () => MockTransactionRemoteDataSource());

  // ── Repository ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDataSource: sl<TransactionLocalDataSource>(),
      remoteDataSource: sl<TransactionRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      writeQueue: sl<WriteQueueService>(),
    ),
  );

  // ── Use cases ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetTransactions(sl<TransactionRepository>()));
  sl.registerLazySingleton(
      () => AddTransaction(sl<TransactionRepository>()));
  sl.registerLazySingleton(
      () => DeleteTransaction(sl<TransactionRepository>()));

  // ── Blocs ────────────────────────────────────────────────────────────────────
  sl.registerFactory(() => SettingsBloc());

  sl.registerFactory(
    () => TransactionBloc(
      getTransactions: sl<GetTransactions>(),
      addTransaction: sl<AddTransaction>(),
      deleteTransaction: sl<DeleteTransaction>(),
      settingsBloc: sl<SettingsBloc>(),
    ),
  );

  // ── Sync service ────────────────────────────────────────────────────────────
  sl.registerLazySingleton(
    () => SyncService(
      local: sl<TransactionLocalDataSource>(),
      remote: sl<TransactionRemoteDataSource>(),
      writeQueue: sl<WriteQueueService>(),
      connectivity: sl<Connectivity>(),
    ),
  );
}
