import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';

class AdminStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<AdminStudentDetailScreen> createState() =>
      _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState
    extends ConsumerState<AdminStudentDetailScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(String profileId) async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) return;

    final client = ref.read(supabaseClientProvider);
    try {
      await client
          .from('profiles')
          .update({'password': password})
          .eq('id', profileId);

      // Update encrypted_password in auth.users if possible
      try {
        await client.rpc(
          'update_auth_user_password',
          params: {'user_id': profileId, 'new_password': password},
        );
      } catch (_) {
        // Fallback: local db may not have this RPC function.
      }

      // Write to audit logs
      try {
        final authProfile = ref.read(authNotifierProvider).profile;
        final actorName = authProfile?['full_name'] ?? 'Super Admin';
        final actorId = authProfile?['id'];

        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': 'UBAH_PASSWORD',
          'description': 'Super Admin mengubah kata sandi siswa dengan ID: $profileId',
          'target_id': profileId,
        });
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diperbarui!'),
            backgroundColor: Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah kata sandi: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleFreezeCard(String studentId, bool currentStatus) async {
    final client = ref.read(supabaseClientProvider);
    final bool newStatus = !currentStatus;

    try {
      // 1. Update students table is_active field
      await client
          .from('students')
          .update({'is_active': newStatus})
          .eq('id', studentId);

      // Write to audit logs
      try {
        final authProfile = ref.read(authNotifierProvider).profile;
        final actorName = authProfile?['full_name'] ?? 'Super Admin';
        final actorId = authProfile?['id'];

        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': newStatus ? 'AKTIFKAN_KARTU' : 'BLOKIR_KARTU',
          'description': 'Super Admin ${newStatus ? "mengaktifkan kembali" : "membekukan"} kartu RFID siswa dengan ID: $studentId',
          'target_id': studentId,
          'old_value': {'is_active': currentStatus},
          'new_value': {'is_active': newStatus},
        });
      } catch (_) {}

      ref.invalidate(adminStudentDetailProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kartu RFID berhasil ${newStatus ? "diaktifkan kembali" : "dibekukan"}.',
            ),
            backgroundColor: newStatus
                ? const Color(0xFF006A35)
                : const Color(0xFF904D00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status kartu: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(String profileId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ubah Kata Sandi'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: _passwordController,
            placeholder: 'Masukkan sandi baru',
            obscureText: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _changePassword(profileId),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _openAllTransactionsScreen({
    required String studentId,
    required Color primaryTeal,
    required Color accentOrange,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: studentId,
          primaryColor: primaryTeal,
          accentColor: accentOrange,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(
      adminStudentDetailProvider(widget.studentId),
    );
    const Color primaryTeal = Color(0xFF003434);
    const Color accentOrange = Color(0xFF904D00);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: primaryTeal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Siswa',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
      ),
      body: studentAsync.when(
        data: (data) {
          final profile = data.profile;
          final student = data.student;
          final List<OperatorTransaction> txs = data.recentTransactions;

          final String fullName = profile.fullName ?? '';
          final String email = profile.email ?? '';
          final String username = profile.username ?? '';
          final String nisn = profile.nisn ?? '';
          final String className = student.class_ ?? 'Belum Diisi';
          final double balance = student.balance;
          final double? dailyLimit = student.dailyLimit;
          final String rfidUid = student.rfidUid ?? 'Belum Terdaftar';
          final bool isCardActive = student.isActive;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primaryTeal.withValues(alpha: 0.1),
                        child: const Icon(
                          CupertinoIcons.person,
                          color: primaryTeal,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelas $className • NISN: ${nisn.isNotEmpty ? nisn : "-"}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Info Bento Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Status Kartu', isCardActive),
                      const Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Color(0xFFE4E2E1),
                      ),
                      _buildTextInfoRow('UID RFID', rfidUid, isMonospace: true),
                      const Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Color(0xFFE4E2E1),
                      ),
                      _buildTextInfoRow(
                        'Username',
                        username.isNotEmpty ? username : '-',
                      ),
                      const Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Color(0xFFE4E2E1),
                      ),
                      _buildTextInfoRow(
                        'Email',
                        email.isNotEmpty ? email : '-',
                      ),
                      const Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Color(0xFFE4E2E1),
                      ),
                      _buildTextInfoRow(
                        'Saldo',
                        CurrencyFormatter.format(balance),
                        highlightColor: primaryTeal,
                        isBold: true,
                      ),
                      const Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Color(0xFFE4E2E1),
                      ),
                      _buildTextInfoRow(
                        'Batas Harian',
                        dailyLimit != null
                            ? CurrencyFormatter.format(dailyLimit)
                            : 'Tidak Terbatas',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Actions grid
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showChangePasswordDialog(profile.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.key, color: primaryTeal),
                              const SizedBox(height: 8),
                              Text(
                                'Ubah\nKata Sandi',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1B1C1B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _toggleFreezeCard(profile.id, isCardActive),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isCardActive
                                ? const Color(0xFFFFDAD6)
                                : const Color(0xFFEAF9EE),
                            border: Border.all(
                              color: isCardActive
                                  ? const Color(0xFFFFDAD6)
                                  : const Color(0xFFEAF9EE),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isCardActive
                                    ? CupertinoIcons.snow
                                    : CupertinoIcons.checkmark_circle,
                                color: isCardActive
                                    ? const Color(0xFFBA1A1A)
                                    : const Color(0xFF006A35),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isCardActive
                                    ? 'Bekukan\nKartu RFID'
                                    : 'Aktifkan\nKartu RFID',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCardActive
                                      ? const Color(0xFFBA1A1A)
                                      : const Color(0xFF006A35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Transaction History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Transaksi',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1B),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openAllTransactionsScreen(
                        studentId: widget.studentId,
                        primaryTeal: primaryTeal,
                        accentOrange: accentOrange,
                      ),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (txs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Belum ada transaksi.',
                        style: GoogleFonts.beVietnamPro(
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: txs.map((tx) {
                      final double amount = tx.totalAmount;
                      final bool isTopup = tx.isTopup;
                      final String canteen = tx.canteenName ?? 'Stan Kantin';
                      final date = tx.createdAt?.toLocal() ?? DateTime.now();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isTopup
                                  ? const Color(0xFFFFDCC3)
                                  : primaryTeal.withValues(alpha: 0.1),
                              child: Icon(
                                isTopup
                                    ? CupertinoIcons.creditcard
                                    : Icons.shopping_bag,
                                color: isTopup ? accentOrange : primaryTeal,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTopup ? 'Top-up Saldo' : canteen,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(date),
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isTopup
                                    ? const Color(0xFF006A35)
                                    : const Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoRow(String label, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3F4848),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEAF9EE) : const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isActive ? 'ACTIVE' : 'BLOCKED',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF006A35)
                  : const Color(0xFFBA1A1A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInfoRow(
    String label,
    String value, {
    Color? highlightColor,
    bool isBold = false,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3F4848),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: isMonospace
                ? TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: highlightColor ?? const Color(0xFF1B1C1B),
                  )
                : GoogleFonts.beVietnamPro(
                    fontSize: isBold ? 20 : 15,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: highlightColor ?? const Color(0xFF1B1C1B),
                  ),
          ),
        ),
      ],
    );
  }
}
