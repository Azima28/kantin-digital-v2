import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/features/shared/screens/student_transactions_screen.dart';

// keuanganStudentDetailProvider is defined in keuangan_providers.dart

class KeuanganStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const KeuanganStudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<KeuanganStudentDetailScreen> createState() =>
      _KeuanganStudentDetailScreenState();
}

class _KeuanganStudentDetailScreenState
    extends ConsumerState<KeuanganStudentDetailScreen> {
  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

  final _passwordController = TextEditingController();
  bool _isUpdatingStatus = false;

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

      try {
        await client.rpc(
          'update_auth_user_password',
          params: {'user_id': profileId, 'new_password': password},
        );
      } catch (_) {}

      // Write to audit logs
      try {
        final authProfile = ref.read(authNotifierProvider).profile;
        final actorName = authProfile?['full_name'] ?? 'Admin Keuangan';
        final actorId = authProfile?['id'];

        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': 'UBAH_PASSWORD',
          'description': 'Mengubah kata sandi siswa dengan ID: $profileId',
          'target_id': profileId,
        });
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
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

  void _openAllTransactionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentTransactionsScreen(
          studentId: widget.studentId,
          primaryColor: primaryTeal,
          accentColor: const Color(0xFF904D00),
        ),
      ),
    );
  }

  Future<void> _toggleAccountStatus(bool currentStatus) async {
    final bool newStatus = !currentStatus;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(newStatus ? 'Aktifkan Akun' : 'Blokir Akun'),
        content: Text(
          newStatus
              ? 'Apakah Anda yakin ingin mengaktifkan kembali akun siswa ini?'
              : 'Apakah Anda yakin ingin memblokir akun siswa ini? Siswa tidak akan bisa melakukan transaksi jajan atau top-up.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: !newStatus,
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isUpdatingStatus = true;
              });

              try {
                final client = ref.read(supabaseClientProvider);
                final profile = ref.read(authNotifierProvider).profile;
                final actorName = profile?['full_name'] ?? 'Admin Keuangan';
                final actorId = profile?['id'];

                // 1. Update profiles is_active
                await client
                    .from('profiles')
                    .update({'is_active': newStatus})
                    .eq('id', widget.studentId);

                // 2. Update students is_active
                await client
                    .from('students')
                    .update({'is_active': newStatus})
                    .eq('id', widget.studentId);

                // 3. Write to audit logs
                await client.from('audit_logs').insert({
                  'actor_id': actorId,
                  'actor_name': actorName,
                  'action_type': newStatus ? 'AKTIFKAN_AKUN' : 'BLOKIR_AKUN',
                  'description':
                      '${newStatus ? "Mengaktifkan" : "Memblokir"} akun siswa dengan ID: ${widget.studentId}',
                  'target_id': widget.studentId,
                  'old_value': {'is_active': currentStatus},
                  'new_value': {'is_active': newStatus},
                });

                ref.invalidate(keuanganStudentDetailProvider(widget.studentId));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Akun siswa berhasil ${newStatus ? "diaktifkan" : "diblokir"}.',
                      ),
                      backgroundColor: newStatus ? successGreen : dangerRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui status: $e'),
                      backgroundColor: dangerRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isUpdatingStatus = false;
                  });
                }
              }
            },
            child: Text(newStatus ? 'Aktifkan' : 'Blokir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      keuanganStudentDetailProvider(widget.studentId),
    );
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Siswa',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: detailAsync.when(
          data: (data) {
            final profile = data.profile;
            final student = data.student;
            final txs = data.recentTransactions;

            final fullName = profile.fullName ?? 'Siswa';
            final email = profile.email ?? '-';
            final nisn = profile.nisn ?? '-';
            final isAccountActive = profile.isActive == true;
            final isCardActive = student.isActive == true;

            final sClass = student.class_ ?? 'Belum Diisi';
            final double balance = student.balance;
            final String? rfid = student.rfidUid;
            final hasCard = rfid != null && rfid.isNotEmpty;

            final String lastTapStr =
                txs.isNotEmpty && txs.first.createdAt != null
                ? DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(txs.first.createdAt!.toLocal())
                : '-';

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                keuanganStudentDetailProvider(widget.studentId),
              ),
              color: primaryTeal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Profile Summary Bento Card ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: primaryTeal.withValues(
                              alpha: 0.08,
                            ),
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : 'S',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1C1B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                           Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: !isAccountActive
                                  ? dangerRed.withValues(alpha: 0.08)
                                  : (!hasCard
                                      ? const Color(0xFFE4E2E1)
                                      : (!isCardActive
                                          ? const Color(0xFFFFF9E6)
                                          : successGreen.withValues(alpha: 0.08))),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              !isAccountActive
                                  ? 'AKUN DIBLOKIR'
                                  : (!hasCard
                                      ? 'BELUM AKTIF'
                                      : (!isCardActive ? 'KARTU DIBLOKIR' : 'AKTIF')),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !isAccountActive
                                    ? dangerRed
                                    : (!hasCard
                                        ? const Color(0xFF6F7978)
                                        : (!isCardActive ? const Color(0xFF8F6B00) : successGreen)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Color(0xFFE4E2E1),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileRow(CupertinoIcons.mail, 'Email', email),
                          const SizedBox(height: 10),
                          _buildProfileRow(
                            CupertinoIcons.book,
                            'Kelas',
                            'Kelas $sClass',
                          ),
                          const SizedBox(height: 10),
                          _buildProfileRow(
                            CupertinoIcons.creditcard,
                            'NISN',
                            nisn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Saldo & Card Info Card ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Saldo & Kartu',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF1B1C1B),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo Aktif',
                                style: GoogleFonts.beVietnamPro(
                                  color: const Color(0xFF6F7978),
                                ),
                              ),
                              Text(
                                fmt.format(balance),
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.bold,
                                  color: balance < 5000
                                      ? dangerRed
                                      : const Color(0xFF1B1C1B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status Kartu',
                                style: GoogleFonts.beVietnamPro(
                                  color: const Color(0xFF6F7978),
                                ),
                              ),
                              Text(
                                hasCard ? 'AKTIF' : 'BELUM AKTIF',
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.bold,
                                  color: hasCard
                                      ? successGreen
                                      : const Color(0xFF6F7978),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'UID Kartu',
                                style: GoogleFonts.beVietnamPro(
                                  color: const Color(0xFF6F7978),
                                ),
                              ),
                              Text(
                                rfid ?? '-',
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B1C1B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Terakhir Tap',
                                style: GoogleFonts.beVietnamPro(
                                  color: const Color(0xFF6F7978),
                                ),
                              ),
                              Text(
                                lastTapStr,
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B1C1B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Aksi Admin Card ───
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              top: 16,
                              right: 20,
                              bottom: 8,
                            ),
                            child: Text(
                              'Aksi Admin',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1B1C1B),
                              ),
                            ),
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.arrow_up_circle,
                            iconColor: successGreen,
                            title: 'Top-Up Saldo Tunai',
                            onTap: () {
                              final studentProfile = StudentWithProfile(
                                id: widget.studentId,
                                fullName: fullName,
                                email: email,
                                nisn: nisn,
                                isActive: isAccountActive,
                                class_: sClass,
                                balance: balance,
                                rfidUid: rfid,
                                cardIsActive: isCardActive,
                              );
                              context.push(
                                '/finance/topup',
                                extra: studentProfile,
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: Color(0xFFE4E2E1),
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.arrow_right_arrow_left_circle,
                            iconColor: dangerRed,
                            title: 'Koreksi Saldo',
                            onTap: () {
                              final studentProfile = StudentWithProfile(
                                id: widget.studentId,
                                fullName: fullName,
                                email: email,
                                nisn: nisn,
                                isActive: isAccountActive,
                                class_: sClass,
                                balance: balance,
                                rfidUid: rfid,
                                cardIsActive: isCardActive,
                              );
                              context.push(
                                '/finance/correction',
                                extra: studentProfile,
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: Color(0xFFE4E2E1),
                          ),
                          _buildActionTile(
                            icon: CupertinoIcons.wifi,
                            iconColor: primaryTeal,
                            title: 'Registrasi / Ganti Kartu NFC',
                            onTap: () {
                              context.push(
                                '/finance/students/${widget.studentId}/card',
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 56,
                            color: Color(0xFFE4E2E1),
                          ),
                          _buildActionTile(
                            icon: Icons.key,
                            iconColor: const Color(0xFF904D00),
                            title: 'Ubah Kata Sandi',
                            onTap: () => _showChangePasswordDialog(profile.id),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Riwayat Transaksi Card ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Riwayat Transaksi (10 Terakhir)',
                                  style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1B1C1B),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _openAllTransactionsScreen,
                                child: Text(
                                  'Lihat Semua',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (txs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'Belum ada transaksi.',
                                  style: GoogleFonts.beVietnamPro(
                                    color: const Color(0xFF6F7978),
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: txs.map((tx) {
                                final isTopup = tx.isTopup;
                                final isSuccess = tx.isSuccess;
                                final double amount = tx.totalAmount;
                                final timestamp =
                                    tx.createdAt?.toLocal() ?? DateTime.now();
                                final timeStr = DateFormat(
                                  'dd MMM, HH:mm',
                                ).format(timestamp);
                                final canteenName = tx.canteenName ?? 'Top-up';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: isTopup
                                                ? successGreen.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : primaryTeal.withValues(
                                                    alpha: 0.08,
                                                  ),
                                            child: Icon(
                                              isTopup
                                                  ? CupertinoIcons.arrow_up
                                                  : CupertinoIcons.cart,
                                              size: 14,
                                              color: isTopup
                                                  ? successGreen
                                                  : primaryTeal,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isTopup
                                                    ? 'Top-Up Saldo'
                                                    : canteenName,
                                                style: GoogleFonts.beVietnamPro(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: const Color(
                                                    0xFF1B1C1B,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                timeStr,
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF6F7978,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isTopup ? "+" : "-"}${fmt.format(amount)}',
                                            style: GoogleFonts.beVietnamPro(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isTopup
                                                  ? successGreen
                                                  : primaryTeal,
                                            ),
                                          ),
                                          if (!isSuccess)
                                            Text(
                                              tx.status
                                                  .toString()
                                                  .toUpperCase(),
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: dangerRed,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Block Account Button ───
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isUpdatingStatus
                            ? null
                            : () => _toggleAccountStatus(isAccountActive),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isAccountActive
                              ? dangerRed.withValues(alpha: 0.08)
                              : successGreen.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isAccountActive
                                  ? dangerRed.withValues(alpha: 0.2)
                                  : successGreen.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: _isUpdatingStatus
                            ? const CupertinoActivityIndicator()
                            : Text(
                                isAccountActive
                                    ? '🚫 BLOKIR AKUN SISWA'
                                    : '✔ AKTIFKAN AKUN SISWA',
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isAccountActive ? dangerRed : successGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CupertinoActivityIndicator(color: primaryTeal),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Gagal memuat profil: $e',
                style: GoogleFonts.beVietnamPro(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6F7978)),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: const Color(0xFF6F7978),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1B),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withValues(alpha: 0.08),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: const Color(0xFF1B1C1B),
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 16,
        color: Color(0xFF6F7978),
      ),
      onTap: onTap,
    );
  }
}
