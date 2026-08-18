import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/core/services/realtime_service.dart';
import 'package:kantin_digital/core/services/secure_session_service.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/app_theme.dart';
import 'package:kantin_digital/core/widgets/premium_background.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';

void main() async {
  // runZonedGuarded bungkus SEMUA inisialisasi + runApp biar zone konsisten.
  // Ini fix "Zone mismatch" — WidgetsFlutterBinding & runApp harus di zone yg sama.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Heningkan peringatan internal buffer discarded pada Flutter Web saat loading awal
    ui.channelBuffers.allowOverflow('flutter/keyevent', true);
    ui.channelBuffers.allowOverflow('flutter/mousecursor', true);
    ui.channelBuffers.allowOverflow('flutter/lifecycle', true);
    ui.channelBuffers.allowOverflow('flutter/navigation', true);

    // Konfigurasi ImageCache Memory Bounds untuk HP Low-End hingga Mid-Range
    // Batasi decoded image cache ke 120 items & 30MB RAM agar super ringan, anti-lag, & bebas OOM
    PaintingBinding.instance.imageCache.maximumSize = 120;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30 MB

    // Custom error page — no red screen of death
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: AppColors.systemBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppStrings.labelError,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan tutup dan buka kembali aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    };

    // Inisialisasi format tanggal bahasa Indonesia & default locale
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
    Intl.defaultLocale = 'id_ID';

    // Inisialisasi secure session storage listener
    await SecureSessionService.initAuthListener();

    runApp(
      const ProviderScope(
        child: MainApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('Unhandled error: $error');
  });
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate Realtime WebSocket Service across all modules
    ref.watch(realtimeServiceProvider);

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Kantin Digital',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return PremiumBackground(child: child!);
      },
    );
  }
}
