import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/custom_confirm_dialog.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_card_registration_form.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_card_registration_success.dart';
import 'package:kantin_digital/core/models/models.dart';


class KeuanganCardRegistrationScreen extends ConsumerStatefulWidget {
  final String studentId;
  const KeuanganCardRegistrationScreen({super.key, required this.studentId});

  @override
  ConsumerState<KeuanganCardRegistrationScreen> createState() => _KeuanganCardRegistrationScreenState();
}

class _KeuanganCardRegistrationScreenState extends ConsumerState<KeuanganCardRegistrationScreen> {
  final TextEditingController _uidController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String _savedUid = '';
  String _successTime = '';

  // Student details loaded locally or via future
  String _fullName = '';
  String _nisn = '';
  String _class = '';
  String? _oldRfid;

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await client.from('profiles').select().eq('id', widget.studentId).maybeSingle();
      final student = await client.from('students').select('*, classes:classes(name), rombels:rombels(name)').eq('id', widget.studentId).maybeSingle();
      final studentModel = Student.fromJson(student ?? {});
      String className = studentModel.class_ ?? '';

      setState(() {
        _fullName = profile?['full_name'] ?? '';
        _nisn = profile?['nisn'] ?? '';
        _class = className;
        _oldRfid = student?['rfid_uid'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memuat profil'),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _simulateNfcScan() {
    // Generate a random 4-byte HEX UID like 04:F8:A1:22
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase());
    final mockUid = parts.join(':');

    setState(() {
      _uidController.text = mockUid;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kartu terdeteksi: $mockUid'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _unlinkCard() async {
    final confirmed = await showCustomConfirmDialog(
      context: context,
      title: 'Hapus Tautan Kartu',
      message: 'Apakah Anda yakin ingin menghapus tautan kartu dari siswa ini? Kartu tidak akan bisa digunakan lagi.',
      confirmLabel: 'Hapus',
      cancelLabel: AppStrings.buttonCancel,
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (confirmed && context.mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final client = ref.read(supabaseClientProvider);
        final profile = ref.read(authNotifierProvider).profile;
        final actorName = profile?['full_name'] ?? 'Admin Keuangan';
        final actorId = profile?['id'];

        // 1. Update students table rfid_uid to null
        await client.from('students').update({'rfid_uid': null}).eq('id', widget.studentId);

        // 2. Write to audit logs
        await client.from('audit_logs').insert({
          'actor_id': actorId,
          'actor_name': actorName,
          'action_type': 'UNLINK_KARTU',
          'description': 'Menghapus tautan kartu RFID dari siswa: $_fullName',
          'target_id': widget.studentId,
          'old_value': {'rfid_uid': _oldRfid},
          'new_value': {'rfid_uid': null},
        });

        // Update detail provider
        ref.invalidate(keuanganStudentDetailProvider(widget.studentId));

        setState(() {
          _oldRfid = null;
          _uidController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.successCardUnlinked),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.labelFailed} menghapus tautan kartu'),
              backgroundColor: AppColors.errorRed2,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _linkCard() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.errorRfidRequired),
          backgroundColor: AppColors.errorRed2,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final profile = ref.read(authNotifierProvider).profile;
      final actorName = profile?['full_name'] ?? 'Admin Keuangan';
      final actorId = profile?['id'];

      // 1. Check if UID is already used by another student
      final List<dynamic> check = await client
          .from('students')
          .select('id, profiles:profiles!students_id_fkey(full_name)')
          .eq('rfid_uid', uid);

      if (check.isNotEmpty) {
        final otherId = check.first['id'];
        if (otherId != widget.studentId) {
          final otherName = check.first['profiles']?['full_name'] ?? 'Siswa Lain';
          throw Exception('Kartu dengan UID ini sudah digunakan oleh $otherName');
        }
      }

      // 2. Update students table rfid_uid and set active
      await client.from('students').update({
        'rfid_uid': uid,
        'is_active': true,
      }).eq('id', widget.studentId);

      // 2b. Update profiles table is_active to true
      await client.from('profiles').update({
        'is_active': true,
      }).eq('id', widget.studentId);

      // 3. Write to audit logs
      await client.from('audit_logs').insert({
        'actor_id': actorId,
        'actor_name': actorName,
        'action_type': 'REGISTRASI_KARTU',
        'description': 'Menautkan kartu RFID ($uid) dan mengaktifkan siswa: $_fullName',
        'target_id': widget.studentId,
        'old_value': {'rfid_uid': _oldRfid, 'is_active': false},
        'new_value': {'rfid_uid': uid, 'is_active': true},
      });

      // Update details
      ref.invalidate(keuanganStudentDetailProvider(widget.studentId));

      setState(() {
        _savedUid = uid;
        _successTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
        _isSuccess = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} menghubungkan kartu'),
            backgroundColor: AppColors.errorRed2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _fullName.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(color: AppColors.darkTeal),
        ),
      );
    }

    if (_isSuccess) {
      return KeuanganCardRegistrationSuccess(
        fullName: _fullName,
        studentClass: _class,
        savedUid: _savedUid,
        successTime: _successTime,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Registrasi Kartu NFC',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.darkTeal,
              fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Siswa: $_fullName (NISN: $_nisn)',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nearBlack),
              ),
              Text(
                'Kelas: $_class · SMP Terpadu',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.mutedGray),
              ),
              const SizedBox(height: 20),
              KeuanganCardRegistrationForm(
                uidController: _uidController,
                oldRfid: _oldRfid,
                isLoading: _isLoading,
                onSimulateNfcScan: _simulateNfcScan,
                onLinkCard: _linkCard,
                onUnlinkCard: _unlinkCard,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
