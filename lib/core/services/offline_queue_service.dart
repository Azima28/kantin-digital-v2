import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Representasi sebuah operasi yang tertunda (belum berhasil dikirim ke server).
class PendingOperation {
  final String id;
  final String table;
  final String action; // 'insert', 'update', 'delete'
  final Map<String, dynamic> data;
  final String? whereColumn;
  final String? whereValue;
  final DateTime createdAt;
  int retryCount;

  PendingOperation({
    required this.id,
    required this.table,
    required this.action,
    required this.data,
    this.whereColumn,
    this.whereValue,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'action': action,
        'data': data,
        'whereColumn': whereColumn,
        'whereValue': whereValue,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'] as String,
        table: json['table'] as String,
        action: json['action'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        whereColumn: json['whereColumn'] as String?,
        whereValue: json['whereValue'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

/// Service untuk mengelola antrian operasi offline.
///
/// Ketika perangkat tidak terhubung ke internet, operasi DB disimpan
/// secara lokal di SharedPreferences. Saat kembali online, antrian
/// diproses secara berurutan dan di-retry jika gagal (maks. 3x).
class OfflineQueueService {
  static const String _queueKey = 'offline_queue_v1';
  static const int _maxRetries = 3;

  final SharedPreferences _prefs;
  final SupabaseClient _client;

  OfflineQueueService({
    required SharedPreferences prefs,
    required SupabaseClient client,
  })  : _prefs = prefs,
        _client = client;

  /// Inisialisasi instance dengan lazy loading SharedPreferences.
  static Future<OfflineQueueService> create(SupabaseClient client) async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineQueueService(prefs: prefs, client: client);
  }

  // ── Membaca / Menulis Antrian ──

  List<PendingOperation> _readQueue() {
    final String? raw = _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) =>
              PendingOperation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('OfflineQueueService._readQueue error: $e');
      return [];
    }
  }

  Future<void> _writeQueue(List<PendingOperation> queue) async {
    final String encoded =
        json.encode(queue.map((op) => op.toJson()).toList());
    await _prefs.setString(_queueKey, encoded);
  }

  /// Tambahkan operasi baru ke antrian.
  Future<void> enqueue(PendingOperation op) async {
    final queue = _readQueue();
    queue.add(op);
    await _writeQueue(queue);
    debugPrint('OfflineQueueService: Enqueued ${op.action} on ${op.table} (id=${op.id})');
  }

  /// Jumlah operasi yang menunggu di antrian.
  int get pendingCount => _readQueue().length;

  /// Hapus seluruh antrian.
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  // ── Proses Antrian ──

  /// Proses semua operasi dalam antrian.
  /// Dipanggil saat perangkat kembali terhubung ke internet.
  ///
  /// Returns jumlah operasi yang berhasil diproses.
  Future<int> processQueue() async {
    final queue = _readQueue();
    if (queue.isEmpty) return 0;

    debugPrint('OfflineQueueService: Processing ${queue.length} pending operations...');

    final List<PendingOperation> failed = [];
    int successCount = 0;

    for (final op in queue) {
      try {
        await _executeOperation(op);
        successCount++;
        debugPrint('OfflineQueueService: ✓ ${op.action} on ${op.table} succeeded');
      } catch (e) {
        op.retryCount++;
        debugPrint(
            'OfflineQueueService: ✗ ${op.action} on ${op.table} failed (retry ${op.retryCount}/$_maxRetries): $e');

        if (op.retryCount < _maxRetries) {
          failed.add(op);
        } else {
          debugPrint(
              'OfflineQueueService: Max retries reached for ${op.id}, dropping operation.');
        }
      }
    }

    await _writeQueue(failed);
    debugPrint(
        'OfflineQueueService: Done. Success=$successCount, Remaining=${failed.length}');
    return successCount;
  }

  Future<void> _executeOperation(PendingOperation op) async {
    switch (op.action) {
      case 'insert':
        await _client.from(op.table).insert(op.data);
        break;

      case 'update':
        if (op.whereColumn != null && op.whereValue != null) {
          await _client
              .from(op.table)
              .update(op.data)
              .eq(op.whereColumn!, op.whereValue!);
        } else {
          throw Exception(
              'Update operation requires whereColumn and whereValue');
        }
        break;

      case 'delete':
        if (op.whereColumn != null && op.whereValue != null) {
          await _client
              .from(op.table)
              .delete()
              .eq(op.whereColumn!, op.whereValue!);
        } else {
          throw Exception(
              'Delete operation requires whereColumn and whereValue');
        }
        break;

      default:
        throw Exception('Unknown action: ${op.action}');
    }
  }

  /// Helper: Buat operasi UPDATE siap antri.
  static PendingOperation makeUpdate({
    required String table,
    required Map<String, dynamic> data,
    required String whereColumn,
    required String whereValue,
  }) {
    return PendingOperation(
      id: '${table}_${whereValue}_${DateTime.now().millisecondsSinceEpoch}',
      table: table,
      action: 'update',
      data: data,
      whereColumn: whereColumn,
      whereValue: whereValue,
      createdAt: DateTime.now(),
    );
  }

  /// Helper: Buat operasi INSERT siap antri.
  static PendingOperation makeInsert({
    required String table,
    required Map<String, dynamic> data,
  }) {
    return PendingOperation(
      id: '${table}_${DateTime.now().millisecondsSinceEpoch}',
      table: table,
      action: 'insert',
      data: data,
      createdAt: DateTime.now(),
    );
  }
}
