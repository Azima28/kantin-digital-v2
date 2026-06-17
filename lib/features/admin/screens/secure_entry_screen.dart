import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SecureEntryScreen extends StatefulWidget {
  const SecureEntryScreen({super.key});

  @override
  State<SecureEntryScreen> createState() => _SecureEntryScreenState();
}

class _SecureEntryScreenState extends State<SecureEntryScreen> {
  final List<int> _enteredPin = [];
  final String _correctPin = '123456';
  bool _hasError = false;

  void _onNumberTap(int number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin.add(number);
        _hasError = false;
      });

      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onBackspaceTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _hasError = false;
      });
    }
  }

  void _verifyPin() {
    final String input = _enteredPin.join();
    if (input == _correctPin) {
      // Direct success
      context.go('/admin');
    } else {
      // Simulate error
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          _enteredPin.clear();
          _hasError = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN Master salah! Coba lagi (Uji Coba PIN: 123456).'),
            backgroundColor: Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  void _simulateBiometric() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Autentikasi Face ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.face, size: 64, color: Color(0xFF003434)),
              const SizedBox(height: 16),
              const Text('Memindai Wajah...'),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context); // Pop dialog
      context.go('/admin');
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF003434);
    const Color onSurfaceVariant = Color(0xFF3F4848);
    const Color surfaceContainerLow = Color(0xFFF5F3F2);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Shield Box
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Kantin Digital',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: primaryTeal,
                          letterSpacing: -0.02,
                        ),
                      ),
                      Text(
                        'Master Control',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Biometric Trigger
                      GestureDetector(
                        onTap: _simulateBiometric,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBFC8C8), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.face,
                            color: primaryTeal,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // PIN text
                      Text(
                        'ENTER MASTER PIN',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurfaceVariant,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PIN Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final isFilled = index < _enteredPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled 
                                  ? primaryTeal 
                                  : (_hasError ? const Color(0xFFBA1A1A).withValues(alpha: 0.2) : const Color(0xFFE4E2E1)),
                              border: Border.all(
                                color: isFilled
                                    ? primaryTeal
                                    : (_hasError ? const Color(0xFFBA1A1A) : const Color(0xFFBFC8C8)),
                                width: 1,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 48),

                      // Numpad Grid
                      SizedBox(
                        width: 260,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            if (index == 9) {
                              return const SizedBox.shrink(); // Empty space
                            }
                            if (index == 11) {
                              return GestureDetector(
                                onTap: _onBackspaceTap,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons.delete_left,
                                      color: onSurfaceVariant,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final int number = index == 10 ? 0 : index + 1;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _onNumberTap(number),
                                borderRadius: BorderRadius.circular(99),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: surfaceContainerLow,
                                  ),
                                  child: Center(
                                    child: Text(
                                      number.toString(),
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1B1C1B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              child: Text(
                '© 2026 Kantin Digital Security.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6F7978),
                  letterSpacing: 0.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
