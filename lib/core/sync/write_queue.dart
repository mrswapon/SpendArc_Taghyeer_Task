import 'package:hive_flutter/hive_flutter.dart';

enum MutationType { add, delete, update }

class PendingMutation {
  final String id;
  final MutationType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  PendingMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.index,
        'payload': payload,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory PendingMutation.fromMap(Map<dynamic, dynamic> map) {
    return PendingMutation(
      id: map['id'] as String,
      type: MutationType.values[map['type'] as int],
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

class WriteQueueService {
  static const String _boxName = 'write_queue';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> enqueue(PendingMutation mutation) async {
    await _box.put(mutation.id, mutation.toMap());
  }

  Future<List<PendingMutation>> getPending() async {
    final mutations = _box.values
        .map((v) => PendingMutation.fromMap(v as Map))
        .toList();
    mutations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return mutations;
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  int get pendingCount => _box.length;
}
