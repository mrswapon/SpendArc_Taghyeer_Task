import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:spend_arc/core/sync/diff_logic.dart';
import 'package:spend_arc/core/sync/write_queue.dart';
import 'package:spend_arc/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:spend_arc/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:spend_arc/features/transactions/data/models/transaction_model.dart';

class _SyncParams {
  final List<Map<String, dynamic>> local;
  final List<Map<String, dynamic>> remote;
  const _SyncParams({required this.local, required this.remote});
}

class _SyncPayload {
  final List<Map<String, dynamic>> added;
  final List<Map<String, dynamic>> updated;
  final List<String> deletedIds;
  const _SyncPayload({
    required this.added,
    required this.updated,
    required this.deletedIds,
  });
}

// Top-level function required for compute().
_SyncPayload _runDiff(_SyncParams params) {
  final local = params.local.map(TransactionModel.fromJson).toList();
  final remote = params.remote.map(TransactionModel.fromJson).toList();

  final result = diffRecords<TransactionModel>(
    local: local,
    remote: remote,
    getId: (t) => t.id,
    isUpdated: (l, r) =>
        l.title != r.title ||
        l.amount != r.amount ||
        l.category != r.category ||
        l.typeIndex != r.typeIndex,
  );

  return _SyncPayload(
    added: result.added.map((t) => t.toJson()).toList(),
    updated: result.updated.map((t) => t.toJson()).toList(),
    deletedIds: result.deletedIds,
  );
}

class SyncService {
  final TransactionLocalDataSource _local;
  final TransactionRemoteDataSource _remote;
  final WriteQueueService _writeQueue;
  final Connectivity _connectivity;

  StreamSubscription<ConnectivityResult>? _connectivitySub;

  SyncService({
    required TransactionLocalDataSource local,
    required TransactionRemoteDataSource remote,
    required WriteQueueService writeQueue,
    required Connectivity connectivity,
  })  : _local = local,
        _remote = remote,
        _writeQueue = writeQueue,
        _connectivity = connectivity;

  void startMonitoring() {
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await replayWriteQueue();
        await backgroundSync();
      }
    });
  }

  void stopMonitoring() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Fetches remote data, diffs against local in an isolate, and applies changes.
  Future<void> backgroundSync() async {
    try {
      final localModels = await _local.getTransactions();
      final remoteModels = await _remote.getTransactions();

      final localJson = localModels.map((t) => t.toJson()).toList();
      final remoteJson = remoteModels.map((t) => t.toJson()).toList();

      // Run heavy diffing in a separate isolate.
      final payload = await compute(
        _runDiff,
        _SyncParams(local: localJson, remote: remoteJson),
      );

      for (final json in payload.added) {
        await _local.addTransaction(TransactionModel.fromJson(json));
      }
      for (final json in payload.updated) {
        await _local.updateTransaction(TransactionModel.fromJson(json));
      }
      for (final id in payload.deletedIds) {
        await _local.deleteTransaction(id);
      }
    } catch (_) {
      // Sync failures are non-fatal; local cache remains available.
    }
  }

  /// Replays any mutations that were queued while offline.
  Future<void> replayWriteQueue() async {
    final pending = await _writeQueue.getPending();
    for (final mutation in pending) {
      try {
        switch (mutation.type) {
          case MutationType.add:
            final model = TransactionModel.fromJson(mutation.payload);
            await _remote.addTransaction(model);
          case MutationType.delete:
            await _remote.deleteTransaction(mutation.payload['id'] as String);
          case MutationType.update:
            final model = TransactionModel.fromJson(mutation.payload);
            await _remote.addTransaction(model); // upsert
        }
        await _writeQueue.remove(mutation.id);
      } catch (_) {
        // Leave in queue; retry on next connectivity change.
      }
    }
  }
}
