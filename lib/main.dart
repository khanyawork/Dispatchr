import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dispatchr is fully browsable via the login screen's Preview Mode
  // (see `dev/preview_mode.dart`) without a working Supabase project, so a
  // missing/placeholder `.env` or unreachable backend must never crash
  // startup — only the "Log In" path (real Supabase auth) needs it.
  try {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    final hasRealCredentials =
        url != null &&
        anonKey != null &&
        url.startsWith('http') &&
        !url.contains('your-project-url');

    if (hasRealCredentials) {
      await Supabase.initialize(url: url, anonKey: anonKey);
    } else if (kDebugMode) {
      debugPrint(
        'Dispatchr: no Supabase credentials configured — running in '
        'preview-mode-only. Use the "Preview mode" buttons on the login '
        'screen to browse the app.',
      );
    }
  } catch (error, stackTrace) {
    // Network/DNS failures, malformed .env, etc. — never block app launch
    // over this; the real-auth "Log In" button will surface its own error
    // if Supabase truly isn't reachable when the user taps it.
    if (kDebugMode) {
      debugPrint('Dispatchr: Supabase initialization skipped ($error)');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: App()));
}
