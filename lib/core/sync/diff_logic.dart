// Pure Dart — no Flutter imports. Safe to run inside a compute() isolate.

class DiffResult<T> {
  final List<T> added;
  final List<T> updated;
  final List<String> deletedIds;

  const DiffResult({
    required this.added,
    required this.updated,
    required this.deletedIds,
  });
}

/// Compares [remote] records against [local] records and returns the diff.
DiffResult<T> diffRecords<T>({
  required List<T> local,
  required List<T> remote,
  required String Function(T) getId,
  required bool Function(T localItem, T remoteItem) isUpdated,
}) {
  final localMap = <String, T>{};
  for (final item in local) {
    localMap[getId(item)] = item;
  }

  final remoteMap = <String, T>{};
  for (final item in remote) {
    remoteMap[getId(item)] = item;
  }

  final added = <T>[];
  final updated = <T>[];
  for (final remoteItem in remote) {
    final id = getId(remoteItem);
    final localItem = localMap[id];
    if (localItem == null) {
      added.add(remoteItem);
    } else if (isUpdated(localItem, remoteItem)) {
      updated.add(remoteItem);
    }
  }

  final deletedIds = local
      .where((item) => !remoteMap.containsKey(getId(item)))
      .map(getId)
      .toList();

  return DiffResult(added: added, updated: updated, deletedIds: deletedIds);
}
