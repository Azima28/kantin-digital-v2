import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/router/app_router.dart';
import 'package:kantin_digital/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Supabase
  // Catatan: Menggunakan parameter default, silakan konfigurasi URL & Anon Key di proyek Anda
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://vgainyzrpfyaakqttjbm.supabase.co'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI'),
  );

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kantin Digital',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
