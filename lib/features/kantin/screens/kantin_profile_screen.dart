import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/change_password_panel.dart';
import 'package:kantin_digital/core/widgets/theme_toggle_tile.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class KantinProfileScreen extends ConsumerStatefulWidget {
  const KantinProfileScreen({super.key});

  @override
  ConsumerState<KantinProfileScreen> createState() => _KantinProfileScreenState();
}

class _KantinProfileScreenState extends ConsumerState<KantinProfileScreen> {
  final TextEditingController _deliveryFeeController = TextEditingController(text: '2000');
  bool _isDeliveryEnabled = true;
  bool _isDeliveryInitialized = false;
  bool _isSavingDelivery = false;

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.white.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              ),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ChangePasswordPanel(parentContext: context),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveDeliverySettings() async {
    final operatorId = ref.read(authNotifierProvider).profile?['id'];
    if (operatorId == null) return;

    final int fee = int.tryParse(_deliveryFeeController.text.replaceAll('.', '').trim()) ?? 2000;

    setState(() => _isSavingDelivery = true);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('canteen_operators').update({
        'is_delivery_enabled': _isDeliveryEnabled,
        'delivery_fee': fee,
      }).eq('id', operatorId);

      ref.invalidate(canteenOperatorProvider);
      ref.invalidate(publicCanteensProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan layanan antar (delivery) berhasil disimpan!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengaturan: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDelivery = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final String canteenName = authState.profile?['canteen_name'] ?? 'Stan Kantin';
    final String fullName = authState.profile?['full_name'] ?? 'Petugas Kantin';
    final String email = authState.profile?['email'] ?? '';
    final String username = authState.profile?['username'] ?? '';
    final String phone = authState.profile?['phone_number'] ?? '-';
    final operatorAsync = ref.watch(canteenOperatorProvider);

    operatorAsync.whenData((op) {
      if (op != null && !_isDeliveryInitialized) {
        _isDeliveryInitialized = true;
        _isDeliveryEnabled = op.isDeliveryEnabled;
        _deliveryFeeController.text = op.deliveryFee.toString();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Akun Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Nebula.teal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bento Profile Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Nebula.teal,
                      Nebula.teal,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent.withValues(alpha: 0.15),
                      child: Text(
                        canteenName.isNotEmpty ? canteenName[0].toUpperCase() : 'K',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: context.cardBg,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      canteenName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.cardBg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.cardBg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Petugas Kantin · Kasir',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.cardBg.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detail Profil Card
              _buildSectionCard(
                title: '${AppStrings.titleDetail} Profil',
                icon: CupertinoIcons.person_crop_circle,
                children: [
                  _buildInfoRow('Nama Stan', canteenName),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('Nama Petugas', fullName),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('Email', email),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('Username', username),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('No. Telepon', phone),
                ],
              ),
              const SizedBox(height: 16),

              // Pengaturan Layanan Antar (Delivery) Card
              _buildDeliverySettingsCard(context),
              const SizedBox(height: 16),

              // Keamanan Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 8),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.lock_shield, color: Nebula.teal, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Keamanan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ThemeToggleTile(showDivider: true),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                        child: Icon(CupertinoIcons.lock_rotation, color: Nebula.teal, size: 20),
                      ),
                      title: Text(
                        AppStrings.adminChangePassword,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Terakhir diubah: belum pernah',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                      trailing: Icon(CupertinoIcons.chevron_forward, size: 16, color: context.textSecondary),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(CupertinoIcons.square_arrow_right, size: 20),
                  label: Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.cardBg,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.rose,
                    foregroundColor: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySettingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
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
              const Icon(CupertinoIcons.car_detailed, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                'Layanan Antar (Delivery)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Switch Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terima Pesanan Delivery',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isDeliveryEnabled
                          ? 'Siswa dapat memilih opsi antar ke meja/kelas'
                          : 'Siswa hanya dapat memilih ambil sendiri (Pickup)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _isDeliveryEnabled,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) {
                  setState(() => _isDeliveryEnabled = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ongkir Input
          if (_isDeliveryEnabled) ...[
            Text(
              'Tarif Ongkos Kirim (Delivery Fee)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _deliveryFeeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
                hintText: '2000',
                filled: true,
                fillColor: context.surfaceBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSavingDelivery ? null : _saveDeliverySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSavingDelivery
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      'Simpan Pengaturan Delivery',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
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
              Icon(icon, color: Nebula.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}