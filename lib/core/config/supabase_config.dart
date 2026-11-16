/// Configuration for Supabase backend connection.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kexphfbypfjcgczwjmxw.supabase.co',
  );

  /// ⬇️ PASTE YOUR SUPABASE ANON / PUBLISHABLE KEY INSIDE THE QUOTES BELOW ⬇️
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE',
  );

  static const bool useRemote = bool.fromEnvironment(
    'USE_REMOTE',
    defaultValue: true,
  );

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      anonKey != 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE' &&
      url.startsWith('http');
}
