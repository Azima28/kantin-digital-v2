// Data model untuk tabel `audit_logs`.
// Mencatat riwayat audit/aktivitas penting di sistem.
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AuditLog {
  final String id;
  final String? actorId;
  final String actorName;
  final String actionType;
  final String description;
  final String? targetId;
  final Map<String, dynamic> oldValue;
  final Map<String, dynamic> newValue;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  const AuditLog({
    required this.id,
    this.actorId,
    required this.actorName,
    required this.actionType,
    required this.description,
    this.targetId,
    this.oldValue = const {},
    this.newValue = const {},
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: (json['id'] ?? '').toString(),
      actorId: json['actor_id'] as String?,
      actorName: (json['actor_name'] ?? '').toString(),
      actionType: (json['action_type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      targetId: json['target_id'] as String?,
      oldValue: _parseJsonb(json['old_value']),
      newValue: _parseJsonb(json['new_value']),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actor_id': actorId,
    'actor_name': actorName,
    'action_type': actionType,
    'description': description,
    'target_id': targetId,
    'old_value': oldValue,
    'new_value': newValue,
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'created_at': createdAt?.toIso8601String(),
  };

  AuditLog copyWith({
    String? id,
    String? actorId,
    String? actorName,
    String? actionType,
    String? description,
    String? targetId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      targetId: targetId ?? this.targetId,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'AuditLog(id: $id, actor: $actorName, action: $actionType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuditLog && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Parse JSONB value from Supabase — handles Map, String (JSON), or null.
  static Map<String, dynamic> _parseJsonb(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (e) {
        debugPrint('AuditLog._parseJsonb: $e');
      }
    }
    return {};
  }
}
