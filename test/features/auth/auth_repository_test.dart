import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dispatchr/features/auth/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = AuthRepository(client: mockClient);
  });

  group('signUp', () {
    test('rejects an unknown role before calling Supabase', () async {
      await expectLater(
        repository.signUp(
          email: 'a@b.com',
          password: 'password1',
          fullName: 'A B',
          role: 'superadmin',
        ),
        throwsA(isA<AuthRepositoryException>()),
      );

      verifyNever(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('wraps a GoTrue AuthException as an AuthRepositoryException', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(AuthException('Email already registered'));

      await expectLater(
        repository.signUp(
          email: 'a@b.com',
          password: 'password1',
          fullName: 'A B',
          role: 'client',
        ),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Email already registered',
          ),
        ),
      );
    });

    test('throws if Supabase signs up without returning a user', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: null, user: null));

      await expectLater(
        repository.signUp(
          email: 'a@b.com',
          password: 'password1',
          fullName: 'A B',
          role: 'client',
        ),
        throwsA(isA<AuthRepositoryException>()),
      );
    });
  });

  group('signIn', () {
    test('returns GoTrue\'s AuthResponse on success', () async {
      final response = AuthResponse(session: null, user: null);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      final result = await repository.signIn(
        email: 'a@b.com',
        password: 'password1',
      );

      expect(result, same(response));
    });

    test('wraps a GoTrue AuthException as an AuthRepositoryException', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(AuthException('Invalid login credentials'));

      await expectLater(
        repository.signIn(email: 'a@b.com', password: 'wrong'),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Invalid login credentials',
          ),
        ),
      );
    });

    test('trims the email before calling GoTrue', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: null, user: null));

      await repository.signIn(email: '  a@b.com  ', password: 'password1');

      verify(
        () => mockAuth.signInWithPassword(
          email: 'a@b.com',
          password: 'password1',
        ),
      ).called(1);
    });
  });

  group('signOut', () {
    test('completes without error on success', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await expectLater(repository.signOut(), completes);
    });

    test('wraps a GoTrue AuthException as an AuthRepositoryException', () async {
      when(() => mockAuth.signOut()).thenThrow(AuthException('Network error'));
      await expectLater(
        repository.signOut(),
        throwsA(isA<AuthRepositoryException>()),
      );
    });
  });

  group('resetPasswordForEmail', () {
    test('trims the email before calling GoTrue', () async {
      when(
        () => mockAuth.resetPasswordForEmail(any()),
      ).thenAnswer((_) async {});

      await repository.resetPasswordForEmail('  a@b.com  ');

      verify(() => mockAuth.resetPasswordForEmail('a@b.com')).called(1);
    });

    test('wraps a GoTrue AuthException as an AuthRepositoryException', () async {
      when(
        () => mockAuth.resetPasswordForEmail(any()),
      ).thenThrow(AuthException('Rate limited'));

      await expectLater(
        repository.resetPasswordForEmail('a@b.com'),
        throwsA(isA<AuthRepositoryException>()),
      );
    });
  });

  group('session/user pass-through', () {
    test('currentUser forwards GoTrue\'s currentUser', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(repository.currentUser, isNull);
    });

    test('currentSession forwards GoTrue\'s currentSession', () {
      when(() => mockAuth.currentSession).thenReturn(null);
      expect(repository.currentSession, isNull);
    });

    test('authStateChanges forwards GoTrue\'s onAuthStateChange stream', () {
      when(
        () => mockAuth.onAuthStateChange,
      ).thenAnswer((_) => const Stream.empty());

      expect(repository.authStateChanges, emitsDone);
    });
  });
}
