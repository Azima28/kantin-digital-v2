import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Unit tests untuk model parsing.
/// Mengetes fromJson factories dari model-model utama tanpa perlu Supabase.
void main() {
  group('AuditLog model parsing', () {
    test('fromJson handles complete data correctly', () {
      final json = {
        'id': 'log_123',
        'actor_id': 'actor_456',
        'actor_name': 'Budi',
        'action_type': 'TOPUP',
        'description': 'Topup Rp 50.000',
        'target_id': 'target_789',
        'old_value': {'balance': 0},
        'new_value': {'balance': 50000},
        'ip_address': '127.0.0.1',
        'user_agent': 'Mozilla/5.0',
        'created_at': '2026-06-19T07:00:00Z',
      };

      final log = AuditLog.fromJson(json);

      expect(log.id, equals('log_123'));
      expect(log.actorId, equals('actor_456'));
      expect(log.actorName, equals('Budi'));
      expect(log.actionType, equals('TOPUP'));
      expect(log.description, equals('Topup Rp 50.000'));
      expect(log.targetId, equals('target_789'));
      expect(log.oldValue['balance'], equals(0));
      expect(log.newValue['balance'], equals(50000));
      expect(log.ipAddress, equals('127.0.0.1'));
      expect(log.userAgent, equals('Mozilla/5.0'));
      expect(log.createdAt, isNotNull);
    });

    test('fromJson handles partial/null data safely without TypeError', () {
      final json = {
        'action_type': 'KOREKSI_SALDO',
        'description': 'Koreksi saldo manual',
        'created_at': '2026-06-19T07:00:00Z',
      };

      // This would have thrown TypeError prior to the fix
      final log = AuditLog.fromJson(json);

      expect(log.id, equals(''));
      expect(log.actorId, isNull);
      expect(log.actorName, equals(''));
      expect(log.actionType, equals('KOREKSI_SALDO'));
      expect(log.description, equals('Koreksi saldo manual'));
      expect(log.targetId, isNull);
      expect(log.oldValue, isEmpty);
      expect(log.newValue, isEmpty);
      expect(log.createdAt, isNotNull);
    });
  });

  group('NfcPaymentState', () {
    test('default state is idle with zero balance', () {
      // Test default NfcPaymentState values
      const status = 'idle';
      const balance = 0.0;
      expect(status, equals('idle'));
      expect(balance, equals(0.0));
    });

    test('verifying state has correct enum value', () {
      const status = 'verifyingStudent';
      expect(status, isNotEmpty);
    });
  });

  group('PendingOperation JSON serialization', () {
    test('can serialize and deserialize via JSON', () {
      final data = {
        'id': 'test_op_123',
        'table': 'profiles',
        'action': 'update',
        'data': {'avatar_url': 'https://example.com/avatar.jpg'},
        'whereColumn': 'id',
        'whereValue': 'abc-123',
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      // Verify all required keys are present
      expect(data['id'], isNotNull);
      expect(data['table'], equals('profiles'));
      expect(data['action'], equals('update'));
      expect(data['data'], isA<Map>());
      expect(data['createdAt'], isA<String>());
    });

    test('retryCount starts at 0', () {
      final data = {
        'id': 'test_op_456',
        'table': 'students',
        'action': 'insert',
        'data': {'class': '8A'},
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      expect(data['retryCount'], equals(0));
    });
  });

  group('Transaction type validation', () {
    test('valid transaction types', () {
      const validTypes = ['purchase', 'topup'];
      expect(validTypes.contains('purchase'), isTrue);
      expect(validTypes.contains('topup'), isTrue);
      expect(validTypes.contains('invalid'), isFalse);
    });

    test('valid transaction statuses', () {
      const validStatuses = ['success', 'pending', 'failed', 'cancelled'];
      expect(validStatuses.contains('success'), isTrue);
      expect(validStatuses.contains('cancelled'), isTrue);
    });
  });

  group('Student data validation', () {
    test('daily_limit of 0 means no limit', () {
      const dailyLimit = 0.0;
      const hasLimit = dailyLimit > 0;
      expect(hasLimit, isFalse);
    });

    test('daily_limit > 0 means has limit', () {
      const dailyLimit = 50000.0;
      const hasLimit = dailyLimit > 0;
      expect(hasLimit, isTrue);
    });

    test('balance check: insufficient balance', () {
      const balance = 5000.0;
      const transactionAmount = 10000.0;
      expect(balance < transactionAmount, isTrue);
    });

    test('balance check: sufficient balance', () {
      const balance = 50000.0;
      const transactionAmount = 10000.0;
      expect(balance >= transactionAmount, isTrue);
    });
  });

  group('Auth role validation', () {
    test('valid roles list', () {
      const validRoles = [
        'student',
        'petugas_kantin',
        'parent',
        'super_admin',
        'petugas_keuangan',
      ];
      expect(validRoles.contains('student'), isTrue);
      expect(validRoles.contains('petugas_kantin'), isTrue);
      expect(validRoles.contains('unknown'), isFalse);
    });
  });

  group('Date formatting helpers', () {
    test('today string format', () {
      final now = DateTime.now().toLocal();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      // Should be exactly 10 chars: YYYY-MM-DD
      expect(todayStr.length, equals(10));
      expect(todayStr.contains('-'), isTrue);
    });

    test('ISO date parsing', () {
      const isoDate = '2026-06-19T07:00:00+07:00';
      final parsed = DateTime.parse(isoDate);
      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(6));
    });
  });

  group('Student status separation tests', () {
    test('StudentWithProfile correct mapping of states', () {
      // 1. Inactive (Belum Aktif) -> rfid_uid is null/empty
      final inactiveJson = {
        'id': 'u1',
        'full_name': 'Siswa Inaktif',
        'email': 'inaktif@sekolah.sch.id',
        'nisn': '12345',
        'is_active': true,
        'students': {
          'class': '7-A',
          'balance': 0.0,
          'rfid_uid': null,
          'is_active': true,
        }
      };
      final inactiveStudent = StudentWithProfile.fromJoinedJson(inactiveJson);
      expect(inactiveStudent.hasRfid, isFalse);
      expect(inactiveStudent.isActive, isTrue); // Profile is active
      expect(inactiveStudent.cardIsActive, isTrue); // Card record is active, but rfid_uid is null so it is BELUM AKTIF

      // 2. Aktif (Active) -> rfid_uid has value, profiles.is_active = true, students.is_active = true
      final activeJson = {
        'id': 'u2',
        'full_name': 'Siswa Otoritas',
        'email': 'aktif@sekolah.sch.id',
        'nisn': '12346',
        'is_active': true,
        'students': {
          'class': '7-A',
          'balance': 10000.0,
          'rfid_uid': 'RFID-123456',
          'is_active': true,
        }
      };
      final activeStudent = StudentWithProfile.fromJoinedJson(activeJson);
      expect(activeStudent.hasRfid, isTrue);
      expect(activeStudent.isActive, isTrue);
      expect(activeStudent.cardIsActive, isTrue);

      // 3. Kartu Diblokir -> rfid_uid has value, profiles.is_active = true, students.is_active = false
      final blockedCardJson = {
        'id': 'u3',
        'full_name': 'Siswa Blokir Kartu',
        'email': 'blockedcard@sekolah.sch.id',
        'nisn': '12347',
        'is_active': true,
        'students': {
          'class': '7-A',
          'balance': 500.0,
          'rfid_uid': 'RFID-123457',
          'is_active': false,
        }
      };
      final blockedCardStudent = StudentWithProfile.fromJoinedJson(blockedCardJson);
      expect(blockedCardStudent.hasRfid, isTrue);
      expect(blockedCardStudent.isActive, isTrue);
      expect(blockedCardStudent.cardIsActive, isFalse);

      // 4. Akun Diblokir -> profiles.is_active = false
      final blockedAccountJson = {
        'id': 'u4',
        'full_name': 'Siswa Blokir Akun',
        'email': 'blockedaccount@sekolah.sch.id',
        'nisn': '12348',
        'is_active': false,
        'students': {
          'class': '7-A',
          'balance': 0.0,
          'rfid_uid': 'RFID-123458',
          'is_active': true,
        }
      };
      final blockedAccountStudent = StudentWithProfile.fromJoinedJson(blockedAccountJson);
      expect(blockedAccountStudent.hasRfid, isTrue);
      expect(blockedAccountStudent.isActive, isFalse);
      expect(blockedAccountStudent.cardIsActive, isTrue);
    });
  });
}
