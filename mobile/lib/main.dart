import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/vialibre_theme.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Edge-to-edge nativo respetando safe areas e íconos oscuros sobre superficie cálida.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(ViaLibreTheme.lightOverlayStyle);
  } catch (_) {}

  try {
    if (Env.isSupabaseConfigured) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
      Env.isInitialized = true;
    }
  } catch (e) {
    debugPrint('Aviso Supabase: $e');
  }

  runApp(const ProviderScope(child: ViaLibreApp()));
}
