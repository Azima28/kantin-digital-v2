/// Data model untuk tabel `notifications`.
///
/// Mencatat log notifikasi sistem/transaksi untuk siswa.
class AppNotification {
  final String id;
  final String studentId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.studentId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
        'created_at': createdAt?.toIso8601String(),
      };

  AppNotification copyWith({
    String? id,
    String? studentId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPurchase => type == 'purchase';
  bool get isTopup => type == 'topup';
  bool get isSystem => type == 'system';

  @override
  String toString() =>
      'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
