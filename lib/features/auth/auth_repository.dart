import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/validators.dart';

/// Thrown when a sign-up/sign-in call fails validation or Supabase rejects
/// the request, so callers can show a message without depending on the
/// Supabase SDK's exception types directly.
class AuthRepositoryException implements Exception {
  AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Supabase Auth calls (`FileManifest.md`: "sign up, sign in, sign out,
/// session"). Scoped to `auth.users` plus the matching `profiles` row
/// (README Section 10) — everything else (business assignment, job data)
/// belongs to feature-specific repositories.
class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Session? get currentSession => _auth.currentSession;

  User? get currentUser => _auth.currentUser;

  /// Emits on every sign-in, sign-out, token refresh, and session recovery.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Creates the `auth.users` record and its matching `profiles` row in one
  /// call, so a signed-up user always has a role attached — the app has no
  /// concept of an authenticated user without one (README Section 8).
  ///
  /// [role] must be one of [Validators.validRoles]; [businessId] is left
  /// null for a `client` signing up ahead of being linked to a business, or
  /// for an `owner` whose business record is created in a later step.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? businessId,
  }) async {
    if (!Validators.validRoles.contains(role)) {
      throw AuthRepositoryException('Invalid role: $role');
    }

    final AuthResponse response;
    try {
      response = await _auth.signUp(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }

    final user = response.user;
    if (user == null) {
      throw AuthRepositoryException('Sign up did not return a user');
    }

    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'business_id': businessId,
        'full_name': fullName.trim(),
        'role': role,
      });
    } on PostgrestException catch (e) {
      throw AuthRepositoryException('Account created but profile setup failed: ${e.message}');
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }
}
