import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

/// Current user/session state (`FileManifest.md`:
/// `lib/features/auth/auth_provider.dart`), plus the login/signup/logout
/// action state consumed by `login_screen.dart` and `signup_screen.dart`.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Raw Supabase auth event stream — sign-in, sign-out, token refresh.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The current user, derived from the live auth stream so it updates
/// immediately on sign-in/out rather than only on first read.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ?? ref.watch(authRepositoryProvider).currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Drives sign-in/sign-up/sign-out from the auth screens, exposing an
/// [AsyncValue] so the UI can show a loading spinner and surface errors
/// (e.g. via `context.showErrorSnackBar` from `context_extensions.dart`)
/// without each screen managing its own `try`/`catch`/`setState`.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signIn(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? businessId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        businessId: businessId,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
