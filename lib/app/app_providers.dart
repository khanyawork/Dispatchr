import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dev/preview_data.dart';
import '../dev/preview_mode.dart';
import 'router.dart';

/// Top-level Riverpod providers shared across the whole app. Feature-level
/// state (e.g. the current user's role, once `auth_provider.dart` exists)
/// should build on top of these rather than duplicate them.

/// The single Supabase client, initialized in `main.dart` before `runApp()`.
/// Repositories should read this instead of calling `Supabase.instance.client`
/// directly, so it can be overridden in tests.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Live stream of Supabase auth state changes (sign in/out/token refresh).
/// `lib/features/auth/auth_provider.dart` will build the role-aware session
/// state (see `AppSession` in `router.dart`) on top of this stream.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// The signed-in user's id — the real Supabase auth id normally, or a
/// fixed preview identity when `PreviewMode.enabled` (see
/// `dev/preview_mode.dart`), so screens like `client_home_screen.dart` and
/// `my_jobs_screen.dart` can be browsed without a real Supabase session.
String? currentUserId(WidgetRef ref) {
  if (PreviewMode.enabled) {
    return switch (AppSession.instance.role) {
      UserRole.client => PreviewIds.client,
      UserRole.technician => PreviewIds.technician,
      UserRole.owner => PreviewIds.owner,
      _ => null,
    };
  }
  return ref.watch(supabaseClientProvider).auth.currentUser?.id;
}
