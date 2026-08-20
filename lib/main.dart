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
  // Heningkan peringatan internal buffer discarded pada Flutter Web saat loading awal
  ui.channelBuffers.allowOverflow('flutter/keyevent', true);
  ui.channelBuffers.resize('flutter/keyevent', 200);
  ui.channelBuffers.allowOverflow('flutter/mousecursor', true);
  ui.channelBuffers.allowOverflow('flutter/lifecycle', true);
  ui.channelBuffers.allowOverflow('flutter/navigation', true);

  // runZonedGuarded bungkus SEMUA inisialisasi + runApp biar zone konsisten.
  // Ini fix "Zone mismatch" — WidgetsFlutterBinding & runApp harus di zone yg sama.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Konfigurasi ImageCache Memory Bounds untuk HP Low-End hingga Mid-Range
    // Batasi decoded image cache ke 120 items & 30MB RAM agar super ringan, anti-lag, & bebas OOM
    PaintingBinding.instance.imageCache.maximumSize = 120;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30 MB

    // Custom error handler & widget builder
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('EngineFlutterView') || msg.contains('isDisposed') || msg.contains('discarded')) {
        return; // Filter web engine teardown / resize artifacts
      }
      debugPrint('[FlutterError] $msg');
    };
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      final msg = error.toString();
      if (msg.contains('EngineFlutterView') || msg.contains('isDisposed') || msg.contains('discarded')) {
        return true;
      }
      debugPrint('[PlatformDispatcher Error] $error');
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: AppColors.systemBackground,
        body: Center(
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
                  'Terjadi kendala visual sementara pada sesi ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    runApp(const ProviderScope(child: MainApp()));
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Muat Ulang Halaman'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
