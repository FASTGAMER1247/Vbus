/// Configuration for Supabase backend connection.
/// Values can be supplied via `--dart-define` at build/run time:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key --dart-define=USE_REMOTE=true
/// ```
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const bool useRemote = bool.fromEnvironment(
    'USE_REMOTE',
    defaultValue: false,
  );

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('http');
}
