/// Data model untuk tabel `system_settings`.
///
/// Menyimpan setelan global sistem dalam format key-value (JSONB).
class SystemSetting {
  final String key;
  final dynamic value;
  final String? updatedBy;
  final DateTime? updatedAt;

  const SystemSetting({
    required this.key,
    required this.value,
    this.updatedBy,
    this.updatedAt,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      key: json['key'] as String,
      value: json['value'],
      updatedBy: json['updated_by'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'updated_by': updatedBy,
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Parse value sebagai boolean.
  bool? get asBool {
    if (value is bool) return value;
    if (value is String) return value == 'true';
    return null;
  }

  /// Parse value sebagai string.
  String? get asString => value?.toString();

  /// Parse value sebagai num.
  num? get asNum {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Parse value sebagai Map.
  Map<String, dynamic>? get asMap {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  SystemSetting copyWith({
    String? key,
    dynamic value,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return SystemSetting(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'SystemSetting(key: $key, value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SystemSetting && key == other.key;

  @override
  int get hashCode => key.hashCode;
}
