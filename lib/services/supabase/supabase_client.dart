import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client singleton/init (`FileManifest.md`:
/// `lib/services/supabase/supabase_client.dart`). Call [AppSupabase.init]
/// once from `main.dart`, before `runApp` — every repository in
/// `features/` then reaches the same client via `Supabase.instance.client`
/// (their default when no client is injected — see e.g.
/// `auth_repository.dart`).
class AppSupabase {
  AppSupabase._();

  static bool _initialized = false;

  /// Loads `.env` (README Section 6.3) and initializes the Supabase SDK.
  /// Safe to call more than once — later calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;

    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env '
        '(copy .env.example to .env and fill in your project\'s values).',
      );
    }

    // supabase_flutter renamed `anonKey` to `publishableKey`; the value is
    // the same key README Section 6.3 calls SUPABASE_ANON_KEY.
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _initialized = true;
  }

  /// The shared client, equivalent to `Supabase.instance.client` — exposed
  /// here so call sites can depend on this file instead of importing
  /// `supabase_flutter` directly everywhere.
  static SupabaseClient get client => Supabase.instance.client;
}
