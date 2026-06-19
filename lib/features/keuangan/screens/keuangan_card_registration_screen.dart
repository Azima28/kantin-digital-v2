import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

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

  static const Color primaryTeal = Color(0xFF003434);
  static const Color successGreen = Color(0xFF006A35);
  static const Color dangerRed = Color(0xFFBA1A1A);

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
      final profile = await client.from('profiles').select().eq('id', widget.studentId).single();
      final student = await client.from('students').select().eq('id', widget.studentId).single();

      setState(() {
        _fullName = profile['full_name'] ?? '';
        _nisn = profile['nisn'] ?? '';
        _class = student['class'] ?? '';
        _oldRfid = student['rfid_uid'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: $e'),
            backgroundColor: dangerRed,
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
        backgroundColor: successGreen,
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
            child: const Text('Batal'),
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
                      content: Text('Tautan kartu berhasil dihapus.'),
                      backgroundColor: successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus tautan kartu: $e'),
                      backgroundColor: dangerRed,
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
            child: const Text('Hapus'),
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
          content: Text('UID kartu tidak boleh kosong.'),
          backgroundColor: dangerRed,
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
        _successTime = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
        _isSuccess = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungkan kartu: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: dangerRed,
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
          child: CupertinoActivityIndicator(color: primaryTeal),
        ),
      );
    }

    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Registrasi Kartu NFC',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 18),
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
                style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1B)),
              ),
              Text(
                'Kelas: $_class · SMP Terpadu',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: const Color(0xFF6F7978)),
              ),
              const SizedBox(height: 20),

              // ─── Scan NFC Bento Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    Text(
                      '📶 SIAP MEMINDAI',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryTeal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tempelkan kartu siswa ke sensor NFC perangkat ini atau gunakan tombol simulasi di bawah.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: const Color(0xFF6F7978),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Animated ripple design
                    GestureDetector(
                      onTap: _simulateNfcScan,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryTeal.withValues(alpha: 0.05),
                          border: Border.all(color: primaryTeal.withValues(alpha: 0.15), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.antenna_radiowaves_left_right,
                            color: primaryTeal,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _simulateNfcScan,
                      icon: const Icon(CupertinoIcons.play_circle_fill, size: 18),
                      label: Text(
                        'Simulasikan Tap Kartu',
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(foregroundColor: primaryTeal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Input UID Manual ───
              Text(
                'UID Kartu (Manual Fallback)',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF1B1C1B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _uidController,
                decoration: InputDecoration(
                  hintText: 'Contoh: 04:F8:A1:22',
                  hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE4E2E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_oldRfid != null && _oldRfid!.isNotEmpty)
                Text(
                  'ℹ UID Lama: $_oldRfid (aktif)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: const Color(0xFF6F7978),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 32),

              // ─── Action Buttons ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _linkCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'HUBUNGKAN KARTU',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (_oldRfid != null && _oldRfid!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _unlinkCard,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: dangerRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Hapus Tautan Kartu',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: dangerRed,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                height: 80,
                width: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF9EE),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: successGreen,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kartu Berhasil Diaktifkan!',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kartu NFC berhasil ditautkan dan akun siswa aktif.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: const Color(0xFF6F7978),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE4E2E1)),
                ),
                child: Column(
                  children: [
                    _buildSuccessRow('Nama Siswa', _fullName),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildSuccessRow('Kelas', 'Kelas $_class'),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildSuccessRow('UID Kartu', _savedUid),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildSuccessRow('Waktu Tautan', _successTime),
                  ],
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop(); // Returns to Student Detail Screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'KEMBALI KE PROFIL SISWA',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B1C1B),
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
