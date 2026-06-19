import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/core/services/offline_queue_service.dart';

void main() {
  group('OfflineQueueService — PendingOperation', () {
    test('makeUpdate creates correct operation', () {
      final op = OfflineQueueService.makeUpdate(
        table: 'students',
        data: {'balance': 50000},
        whereColumn: 'id',
        whereValue: 'student-123',
      );

      expect(op.table, equals('students'));
      expect(op.action, equals('update'));
      expect(op.data['balance'], equals(50000));
      expect(op.whereColumn, equals('id'));
      expect(op.whereValue, equals('student-123'));
      expect(op.retryCount, equals(0));
    });

    test('makeInsert creates correct operation', () {
      final op = OfflineQueueService.makeInsert(
        table: 'notifications',
        data: {'title': 'Test', 'message': 'Hello', 'type': 'system'},
      );

      expect(op.table, equals('notifications'));
      expect(op.action, equals('insert'));
      expect(op.data['title'], equals('Test'));
      expect(op.whereColumn, isNull);
      expect(op.whereValue, isNull);
    });

    test('PendingOperation serializes to JSON correctly', () {
      final op = OfflineQueueService.makeUpdate(
        table: 'profiles',
        data: {'avatar_url': 'https://example.com/avatar.jpg'},
        whereColumn: 'id',
        whereValue: 'user-abc',
      );

      final json = op.toJson();

      expect(json['id'], isA<String>());
      expect(json['table'], equals('profiles'));
      expect(json['action'], equals('update'));
      expect(json['data'], isA<Map>());
      expect(json['whereColumn'], equals('id'));
      expect(json['whereValue'], equals('user-abc'));
      expect(json['createdAt'], isA<String>());
      expect(json['retryCount'], equals(0));
    });

    test('PendingOperation deserializes from JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'test_op_789',
        'table': 'students',
        'action': 'update',
        'data': {'daily_limit': 75000.0},
        'whereColumn': 'id',
        'whereValue': 'student-xyz',
        'createdAt': now.toIso8601String(),
        'retryCount': 2,
      };

      final op = PendingOperation.fromJson(json);

      expect(op.id, equals('test_op_789'));
      expect(op.table, equals('students'));
      expect(op.action, equals('update'));
      expect(op.data['daily_limit'], equals(75000.0));
      expect(op.retryCount, equals(2));
    });

    test('retryCount increments correctly', () {
      final op = OfflineQueueService.makeInsert(
        table: 'test_table',
        data: {'key': 'value'},
      );

      expect(op.retryCount, equals(0));
      op.retryCount++;
      expect(op.retryCount, equals(1));
      op.retryCount++;
      expect(op.retryCount, equals(2));
    });

    test('operation ID includes table name', () {
      final op = OfflineQueueService.makeUpdate(
        table: 'profiles',
        data: {'full_name': 'Budi'},
        whereColumn: 'id',
        whereValue: 'xyz',
      );

      expect(op.id, contains('profiles'));
    });
  });
}
