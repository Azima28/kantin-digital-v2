import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_card_registration_form.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_card_registration_success.dart';

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
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/student/lookup', queryParams: {'id': widget.studentId});

      if (response.success && response.data != null) {
        final profile = response.data as Map<String, dynamic>;
        setState(() {
          _fullName = profile['full_name']?.toString() ?? '';
          _nisn = profile['nisn']?.toString() ?? '';
          _class = profile['class']?.toString() ?? '';
          _oldRfid = profile['rfid_uid']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} memuat profil: $e'),
            backgroundColor: Nebula.rose,
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
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase());
    final mockUid = parts.join(':');

    setState(() {
      _uidController.text = mockUid;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kartu terdeteksi: $mockUid'),
        backgroundColor: Nebula.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _unlinkCard() async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Tautan Kartu'),
        content: const Text('Apakah Anda yakin ingin menghapus tautan kartu dari siswa ini? Kartu tidak akan bisa digunakan lagi.'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isLoading = true;
              });

              try {
                final apiClient = ref.read(apiClientProvider);
                await apiClient.patch('/student/card-status', body: {
                  'student_id': widget.studentId,
                  'rfid_uid': null,
                });

                // Update detail provider
                ref.invalidate(keuanganStudentDetailProvider(widget.studentId));
                ref.invalidate(keuanganHistoryProvider);

                setState(() {
                  _oldRfid = null;
                  _uidController.clear();
                });

                if (mounted) {
                  AppToast.showSuccess(
                    context,
                    title: 'Berhasil Disimpan',
                    message: AppStrings.successCardUnlinked,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppStrings.labelFailed} menghapus tautan kartu'),
                      backgroundColor: Nebula.rose,
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
            },
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _linkCard() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.errorRfidRequired),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/student/card-status', body: {
        'student_id': widget.studentId,
        'rfid_uid': uid,
        'is_active': true,
      });

      // Update details
      ref.invalidate(keuanganStudentDetailProvider(widget.studentId));
      ref.invalidate(keuanganHistoryProvider);

      setState(() {
        _savedUid = uid;
        _successTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
        _isSuccess = true;
      });

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil Disimpan',
          message: 'Kartu RFID $uid telah aman ditautkan ke $_fullName.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mendaftarkan kartu: $e'),
            backgroundColor: Nebula.rose,
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
          child: CupertinoActivityIndicator(color: Nebula.teal),
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
              color: Nebula.teal,
              fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                        color: context.textPrimary),
                  ),
                  Text(
                    'Kelas: $_class · SMP Terpadu',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: context.textSecondary),
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
        ),
      ),
    );
  }
}
