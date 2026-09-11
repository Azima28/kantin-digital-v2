// Data model untuk tabel `audit_logs`.
// Mencatat riwayat audit/aktivitas penting di sistem.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

class AuditLog {
  final String id;
  final String? actorId;
  final String actorName;
  final String actorRole;
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
    this.actorRole = '',
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
      actorRole: (json['actor_role'] ?? '').toString(),
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

  /// Label jenis aksi dalam Bahasa Indonesia alami untuk tampilan UI
  String get actionTypeDisplay {
    final raw = actionType.toUpperCase().trim();
    switch (raw) {
      case 'STUDENT_TOPUP':
      case 'STUDENT TOPUP':
      case 'TOPUP':
      case 'TOPUP_TUNAI':
      case 'TOPUP_SALDO':
        return 'Top-Up Saldo Siswa';
      case 'STUDENT_PROFILE_UPDATED':
      case 'STUDENT PROFILE UPDATED':
        return 'Profil Siswa';
      case 'USER_STATUS_CHANGED':
      case 'USER STATUS CHANGED':
      case 'STUDENT_STATUS_CHANGED':
        return 'Status Pengguna';
      case 'BATAL_PESANAN':
      case 'ORDER_CANCELLED':
        return 'Pembatalan Pesanan';
      case 'KOREKSI_SALDO':
        return 'Koreksi Saldo';
      case 'REGISTRASI_KARTU':
        return 'Registrasi Kartu RFID';
      case 'UNLINK_KARTU':
        return 'Hapus Tautan Kartu';
      case 'BLOKIR_KARTU':
      case 'FREEZE_CARD':
      case 'CARD_STATUS_UPDATED':
        return 'Blokir Kartu RFID';
      case 'AKTIFKAN_KARTU':
      case 'UNFREEZE_CARD':
        return 'Aktivasi Kartu RFID';
      case 'MERCHANT_PAYOUT':
      case 'WITHDRAWAL':
        return 'Pencairan Kas Stan';
      case 'MERCHANT_BALANCE_ADJUSTMENT':
        return 'Penyesuaian Saldo Stan';
      case 'ORDER_CREATED':
        return 'Pesanan Baru Dibuat';
      case 'ORDER_STATUS_CHANGED':
        return 'Perubahan Status Pesanan';
      case 'SHIFT_CLOSED':
      case 'CLOSE_SHIFT':
      case 'TUTUP_KASIR_SHIFT':
        return 'Tutup Shift Kasir';
      case 'SHIFT_VERIFIED':
      case 'VERIFIKASI_SERAH_TERIMA_SHIFT':
        return 'Verifikasi Shift Kasir';
      case 'USER_CREATED':
      case 'STUDENT_CREATED':
        return 'Pendaftaran Akun';
      case 'USER_UPDATED':
      case 'STUDENT_UPDATED':
        return 'Pembaruan Data Akun';
      case 'USER_DELETED':
        return 'Penghapusan Akun';
      case 'PASSWORD_CHANGED':
      case 'USER_PASSWORD_RESET':
        return 'Kata Sandi';
      case 'STUDENT_PIN_RESET':
      case 'STUDENT_PIN_CHANGED':
      case 'CHANGE_PIN':
      case 'PIN_CHANGED':
        return 'PIN Transaksi';
      case 'ACADEMIC_YEAR_CHANGED':
        return 'Tahun Ajaran';
      case 'SYSTEM_SETTINGS_UPDATED':
        return 'Pengaturan Sistem';
    }

    String res = raw;
    res = res.replaceAll('_', ' ');
    return res;
  }

  /// Judul aktivitas audit yang bersih, formal, dan mudah dibaca (bukan format kode / nama tabel)
  String get displayTitle {
    final raw = actionType.toUpperCase().trim();
    switch (raw) {
      case 'STUDENT_PROFILE_UPDATED':
      case 'STUDENT PROFILE UPDATED':
        return 'Pembaruan Profil Siswa';
      case 'TUTUP_KASIR_SHIFT':
      case 'SHIFT_CLOSED':
      case 'CLOSE_SHIFT':
        return 'Penutupan Shift Kasir';
      case 'VERIFIKASI_SERAH_TERIMA_SHIFT':
      case 'SHIFT_VERIFIED':
        return 'Verifikasi Serah Terima Kasir';
      case 'STUDENT_TOPUP':
      case 'STUDENT TOPUP':
      case 'TOPUP':
      case 'TOPUP_TUNAI':
      case 'TOPUP_SALDO':
        return 'Top-Up Saldo Siswa';
      case 'BATAL_PESANAN':
      case 'ORDER_CANCELLED':
        return 'Pembatalan Pesanan';
      case 'USER_STATUS_CHANGED':
      case 'STUDENT_STATUS_CHANGED':
        return 'Perubahan Status Akun';
      case 'PASSWORD_CHANGED':
      case 'USER_PASSWORD_RESET':
        return 'Perubahan Kata Sandi';
      case 'STUDENT_PIN_RESET':
      case 'STUDENT_PIN_CHANGED':
      case 'CHANGE_PIN':
      case 'PIN_CHANGED':
        return 'Perubahan PIN Transaksi';
      case 'REGISTRASI_KARTU':
        return 'Registrasi Kartu RFID';
      case 'UNLINK_KARTU':
        return 'Pelepasan Tautan Kartu';
      case 'BLOKIR_KARTU':
      case 'FREEZE_CARD':
      case 'CARD_STATUS_UPDATED':
        return 'Pemblokiran Kartu RFID';
      case 'AKTIFKAN_KARTU':
      case 'UNFREEZE_CARD':
        return 'Aktivasi Kartu RFID';
      case 'KOREKSI_SALDO':
        return 'Koreksi Saldo';
      case 'MERCHANT_PAYOUT':
      case 'WITHDRAWAL':
        return 'Pencairan Kas Stan';
      case 'MERCHANT_BALANCE_ADJUSTMENT':
        return 'Penyesuaian Saldo Stan';
      case 'USER_CREATED':
      case 'STUDENT_CREATED':
        return 'Pendaftaran Akun Baru';
      case 'USER_UPDATED':
      case 'STUDENT_UPDATED':
        return 'Pembaruan Data Pengguna';
      case 'USER_DELETED':
        return 'Penghapusan Akun';
      case 'ORDER_CREATED':
        return 'Pesanan Baru Masuk';
      case 'ORDER_STATUS_CHANGED':
        return 'Perubahan Status Pesanan';
      case 'ACADEMIC_YEAR_CHANGED':
        return 'Perubahan Tahun Ajaran';
      case 'SYSTEM_SETTINGS_UPDATED':
        return 'Pembaruan Pengaturan Sistem';
    }
    return actionTypeDisplay;
  }

  /// Ringkasan naratif ramah pengguna (menghindari nama tabel SQL atau format teknis mentah)
  String get displaySubtitle {
    final raw = actionType.toUpperCase().trim();

    final studentName = newValue['student_name']?.toString() ??
        oldValue['student_name']?.toString() ??
        newValue['full_name']?.toString() ??
        oldValue['full_name']?.toString() ??
        '';

    final canteenName = newValue['canteen_name']?.toString() ??
        oldValue['canteen_name']?.toString() ??
        newValue['operator_name']?.toString() ??
        '';

    final int amount = int.tryParse(newValue['amount']?.toString() ?? '') ??
        int.tryParse(newValue['total_amount']?.toString() ?? '') ??
        int.tryParse(newValue['refund_amount']?.toString() ?? '') ??
        0;

    switch (raw) {
      case 'STUDENT_PROFILE_UPDATED':
      case 'STUDENT PROFILE UPDATED':
        if (studentName.isNotEmpty) {
          return 'Data profil siswa $studentName berhasil diperbarui.';
        }
        return 'Data profil siswa berhasil diperbarui.';

      case 'TUTUP_KASIR_SHIFT':
      case 'SHIFT_CLOSED':
      case 'CLOSE_SHIFT':
        final desc = newValue['desc']?.toString() ?? '';
        if (desc.isNotEmpty && !desc.contains('pada ')) {
          return desc;
        }
        return 'Sesi shift kasir resmi ditutup dan dicatat ke sistem.';

      case 'VERIFIKASI_SERAH_TERIMA_SHIFT':
      case 'SHIFT_VERIFIED':
        final desc = newValue['desc']?.toString() ?? '';
        if (desc.isNotEmpty && !desc.contains('pada ')) {
          return desc;
        }
        return 'Laporan serah terima shift kasir telah diverifikasi.';

      case 'STUDENT_TOPUP':
      case 'STUDENT TOPUP':
      case 'TOPUP':
      case 'TOPUP_TUNAI':
      case 'TOPUP_SALDO':
        final amtStr = amount > 0 ? CurrencyFormatter.format(amount) : '';
        final method = (newValue['method']?.toString().toLowerCase() == 'qris') ? 'QRIS' : 'Tunai';
        if (studentName.isNotEmpty && amtStr.isNotEmpty) {
          return 'Top-up saldo $studentName sebesar $amtStr ($method).';
        } else if (amtStr.isNotEmpty) {
          return 'Top-up saldo siswa sebesar $amtStr ($method).';
        } else if (studentName.isNotEmpty) {
          return 'Pengisian saldo siswa untuk $studentName berhasil.';
        }
        return 'Pengisian saldo dompet siswa berhasil diproses.';

      case 'BATAL_PESANAN':
      case 'ORDER_CANCELLED':
        final amtStr = amount > 0 ? ' (${CurrencyFormatter.format(amount)})' : '';
        if (studentName.isNotEmpty) {
          return 'Pesanan $studentName dibatalkan. Saldo$amtStr telah dikembalikan.';
        }
        return 'Pesanan dibatalkan dan saldo telah dikembalikan ke kartu.';

      case 'USER_STATUS_CHANGED':
      case 'STUDENT_STATUS_CHANGED':
        final bool? isActive = newValue['is_active'] is bool ? newValue['is_active'] as bool : null;
        final target = studentName.isNotEmpty ? ' untuk $studentName' : '';
        if (isActive == true) {
          return 'Status akun$target telah diaktifkan kembali.';
        } else if (isActive == false) {
          return 'Status akun$target telah dinonaktifkan / dibekukan.';
        }
        return 'Perubahan status keaktifan akun pengguna$target.';

      case 'PASSWORD_CHANGED':
      case 'USER_PASSWORD_RESET':
        final target = studentName.isNotEmpty ? ' untuk $studentName' : '';
        return 'Kata sandi akun$target berhasil diperbarui.';

      case 'STUDENT_PIN_RESET':
      case 'STUDENT_PIN_CHANGED':
      case 'CHANGE_PIN':
      case 'PIN_CHANGED':
        final target = studentName.isNotEmpty ? ' untuk $studentName' : '';
        return 'PIN transaksi 6-digit dompet siswa$target berhasil diperbarui.';

      case 'REGISTRASI_KARTU':
        final rfid = newValue['rfid_uid']?.toString() ?? '';
        final rfidPart = rfid.isNotEmpty ? ' (UID: $rfid)' : '';
        final target = studentName.isNotEmpty ? ' kepada $studentName' : '';
        return 'Pemasangan kartu fisik RFID baru$target$rfidPart.';

      case 'UNLINK_KARTU':
        final target = studentName.isNotEmpty ? ' dari $studentName' : '';
        return 'Pelepasan tautan kartu fisik RFID$target.';

      case 'BLOKIR_KARTU':
      case 'FREEZE_CARD':
      case 'CARD_STATUS_UPDATED':
        final target = studentName.isNotEmpty ? ' milik $studentName' : '';
        return 'Kartu fisik RFID$target telah dibekukan sementara.';

      case 'AKTIFKAN_KARTU':
      case 'UNFREEZE_CARD':
        final target = studentName.isNotEmpty ? ' milik $studentName' : '';
        return 'Kartu fisik RFID$target telah diaktifkan kembali.';

      case 'KOREKSI_SALDO':
        final reason = newValue['reason']?.toString() ?? '';
        final target = studentName.isNotEmpty ? ' untuk $studentName' : '';
        if (reason.isNotEmpty) {
          return 'Koreksi saldo$target. Alasan: $reason.';
        }
        return 'Koreksi penyesuaian saldo$target berhasil dicatat.';

      case 'MERCHANT_PAYOUT':
      case 'WITHDRAWAL':
        final amtStr = amount > 0 ? ' sebesar ${CurrencyFormatter.format(amount)}' : '';
        final cPart = canteenName.isNotEmpty ? ' stan $canteenName' : '';
        return 'Pencairan kas$cPart$amtStr berhasil disetujui.';

      case 'MERCHANT_BALANCE_ADJUSTMENT':
        final cPart = canteenName.isNotEmpty ? ' stan $canteenName' : '';
        return 'Penyesuaian saldo kas$cPart.';

      case 'USER_CREATED':
      case 'STUDENT_CREATED':
        if (studentName.isNotEmpty) {
          return 'Pendaftaran akun baru untuk $studentName.';
        }
        return 'Akun pengguna baru berhasil didaftarkan.';

      case 'USER_UPDATED':
      case 'STUDENT_UPDATED':
        if (studentName.isNotEmpty) {
          return 'Pembaruan data akun $studentName.';
        }
        return 'Data akun pengguna berhasil diperbarui.';

      case 'USER_DELETED':
        return 'Akun pengguna telah dihapus dari sistem.';
    }

    return localizedDescription;
  }

  /// Peran pelaksana dalam bahasa Indonesia
  String get actorRoleDisplay {
    final raw = actorRole.toLowerCase().trim();
    switch (raw) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Administrator';
      case 'petugas_keuangan':
        return 'Petugas Keuangan';
      case 'petugas_kantin':
        return 'Kasir Kantin';
      case 'student':
        return 'Siswa';
      case 'parent':
        return 'Orang Tua / Wali';
    }
    if (raw.isNotEmpty) {
      return raw.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
    return 'Pengguna';
  }

  /// Keterangan audit dalam Bahasa Indonesia alami
  String get localizedDescription {
    String desc = description.trim();
    if (desc.isEmpty) {
      return displayTitle;
    }

    // Bersihkan frasa "X pada Y" format database
    desc = desc.replaceAll('pada students', '');
    desc = desc.replaceAll('pada profiles', '');
    desc = desc.replaceAll('pada orders', '');
    desc = desc.replaceAll('pada transactions', '');
    desc = desc.replaceAll('pada cards', '');
    desc = desc.replaceAll('pada shifts', '');
    desc = desc.replaceAll('pada canteens', '');
    desc = desc.replaceAll('pada cashier_shifts', '');

    desc = desc.replaceAll('STUDENT_PROFILE_UPDATED', 'Pembaruan profil siswa');
    desc = desc.replaceAll('TUTUP_KASIR_SHIFT', 'Penutupan shift kasir');
    desc = desc.replaceAll('VERIFIKASI_SERAH_TERIMA_SHIFT', 'Verifikasi serah terima kasir');
    desc = desc.replaceAll('STUDENT_TOPUP', 'Top-up saldo siswa');
    desc = desc.replaceAll('STUDENT TOPUP', 'Top-up saldo siswa');
    desc = desc.replaceAll('USER_STATUS_CHANGED', 'Perubahan status pengguna');
    desc = desc.replaceAll('USER STATUS CHANGED', 'Perubahan status pengguna');
    desc = desc.replaceAll('STUDENT_STATUS_CHANGED', 'Perubahan status siswa');
    desc = desc.replaceAll('USER_PASSWORD_RESET', 'Perubahan kata sandi');
    desc = desc.replaceAll('PASSWORD_CHANGED', 'Perubahan kata sandi');
    desc = desc.replaceAll('STUDENT_PIN_RESET', 'Perubahan PIN transaksi');
    desc = desc.replaceAll('STUDENT_PIN_CHANGED', 'Perubahan PIN transaksi');
    desc = desc.replaceAll('REGISTRASI_KARTU', 'Registrasi kartu RFID');
    desc = desc.replaceAll('UNLINK_KARTU', 'Pelepasan tautan kartu');
    desc = desc.replaceAll('BLOKIR_KARTU', 'Pemblokiran kartu RFID');
    desc = desc.replaceAll('AKTIFKAN_KARTU', 'Aktivasi kartu RFID');
    desc = desc.replaceAll('KOREKSI_SALDO', 'Koreksi saldo');
    desc = desc.replaceAll('BATAL_PESANAN', 'Pembatalan pesanan');
    desc = desc.replaceAll('MERCHANT_PAYOUT', 'Pencairan kas stan');
    desc = desc.replaceAll('USER_CREATED', 'Pendaftaran akun baru');
    desc = desc.replaceAll('USER_UPDATED', 'Pembaruan data akun');
    desc = desc.replaceAll('USER_DELETED', 'Penghapusan akun');
    desc = desc.replaceAll('_', ' ').trim();

    return desc.isNotEmpty ? desc : displayTitle;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuditLog && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Parse JSONB value from database — handles Map, String (JSON), or null.
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
