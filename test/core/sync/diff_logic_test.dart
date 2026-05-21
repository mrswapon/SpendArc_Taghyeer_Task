// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:spend_arc/core/sync/diff_logic.dart';

// Simple data class for testing — no Flutter / Hive dependency needed here.
class _Record {
  final String id;
  final String value;
  const _Record(this.id, this.value);
}

void main() {
  // Test 5: Diff logic identifies added, updated, and deleted records.
  group('diffRecords', () {
    final local = [
      const _Record('1', 'apple'),
      const _Record('2', 'banana'),
      const _Record('3', 'cherry'),
    ];

    test('detects newly added records', () {
      final remote = [
        ...local,
        const _Record('4', 'date'), // added remotely
      ];

      final result = diffRecords<_Record>(
        local: local,
        remote: remote,
        getId: (r) => r.id,
        isUpdated: (l, r) => l.value != r.value,
      );

      expect(result.added.length, 1);
      expect(result.added.first.id, '4');
      expect(result.updated, isEmpty);
      expect(result.deletedIds, isEmpty);
    });

    test('detects updated records', () {
      final remote = [
        const _Record('1', 'apple'),
        const _Record('2', 'BANANA_UPDATED'), // value changed
        const _Record('3', 'cherry'),
      ];

      final result = diffRecords<_Record>(
        local: local,
        remote: remote,
        getId: (r) => r.id,
        isUpdated: (l, r) => l.value != r.value,
      );

      expect(result.added, isEmpty);
      expect(result.updated.length, 1);
      expect(result.updated.first.id, '2');
      expect(result.deletedIds, isEmpty);
    });

    test('detects deleted records', () {
      final remote = [
        const _Record('1', 'apple'),
        // record '2' removed remotely
        const _Record('3', 'cherry'),
      ];

      final result = diffRecords<_Record>(
        local: local,
        remote: remote,
        getId: (r) => r.id,
        isUpdated: (l, r) => l.value != r.value,
      );

      expect(result.added, isEmpty);
      expect(result.updated, isEmpty);
      expect(result.deletedIds.length, 1);
      expect(result.deletedIds.first, '2');
    });

    test('handles all three types of change simultaneously', () {
      final remote = [
        const _Record('1', 'apple'),
        const _Record('2', 'BANANA_CHANGED'), // updated
        // '3' removed
        const _Record('5', 'elderberry'), // added
      ];

      final result = diffRecords<_Record>(
        local: local,
        remote: remote,
        getId: (r) => r.id,
        isUpdated: (l, r) => l.value != r.value,
      );

      expect(result.added.map((r) => r.id), contains('5'));
      expect(result.updated.map((r) => r.id), contains('2'));
      expect(result.deletedIds, contains('3'));
    });

    test('returns empty diff when local and remote are identical', () {
      final result = diffRecords<_Record>(
        local: local,
        remote: local,
        getId: (r) => r.id,
        isUpdated: (l, r) => l.value != r.value,
      );

      expect(result.added, isEmpty);
      expect(result.updated, isEmpty);
      expect(result.deletedIds, isEmpty);
    });
  });
}
