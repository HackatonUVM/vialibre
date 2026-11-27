/// Configuración de variables pasadas en tiempo de compilación con `--dart-define`
/// o `--dart-define-from-file=.env.json`.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aiztivgrynirvdkcdugd.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String bffBaseUrl = String.fromEnvironment(
    'BFF_BASE_URL',
    defaultValue: 'https://bff-steel.vercel.app',
  );

  static const String googleMapsMapId = String.fromEnvironment(
    'GOOGLE_MAPS_MAP_ID',
    defaultValue: '',
  );

  static bool isInitialized = false;

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey.startsWith('ey');
}
