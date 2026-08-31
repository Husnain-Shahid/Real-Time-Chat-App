import 'package:chat_application/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks/firebase_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(FakeUser());
  });

  group('AuthService Unit Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockDatabaseService mockDatabaseService;
    late AuthService authService;

    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockDatabaseService = MockDatabaseService();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();

      when(() => mockUser.uid).thenReturn('user-12345');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUserCredential.user).thenReturn(mockUser);

      // Default mock for ensureUserProfileExists
      when(() => mockDatabaseService.ensureUserProfileExists(
            any(),
            customName: any(named: 'customName'),
          )).thenAnswer((_) async {});

      authService = AuthService(
        auth: mockAuth,
        googleSignIn: mockGoogleSignIn,
        databaseService: mockDatabaseService,
      );
    });

    test('currentUser returns current user from FirebaseAuth', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = authService.currentUser;

      expect(result, equals(mockUser));
      expect(result?.uid, 'user-12345');
      expect(result?.email, 'test@example.com');
      verify(() => mockAuth.currentUser).called(1);
    });

    test('authStateChanges returns stream of auth state', () {
      final userStream = Stream<User?>.fromIterable([mockUser, null]);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => userStream);

      expect(authService.authStateChanges, emitsInOrder([mockUser, null]));
      verify(() => mockAuth.authStateChanges()).called(1);
    });

    group('signInWithEmailAndPassword', () {
      test('successfully signs in and ensures user profile exists in database', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@example.com',
              password: 'password123',
            )).thenAnswer((_) async => mockUserCredential);

        final result = await authService.signInWithEmailAndPassword(
          email: ' test@example.com ',
          password: ' password123 ',
        );

        expect(result, equals(mockUserCredential));
        expect(result.user?.uid, 'user-12345');
        verify(() => mockAuth.signInWithEmailAndPassword(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
        verify(() => mockDatabaseService.ensureUserProfileExists(mockUser)).called(1);
      });

      test('throws FirebaseAuthException when credentials are invalid', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'wrong@example.com',
              password: 'badpassword',
            )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        ));

        expect(
          () => authService.signInWithEmailAndPassword(
            email: 'wrong@example.com',
            password: 'badpassword',
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          )),
        );
        verifyNever(() => mockDatabaseService.ensureUserProfileExists(any()));
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('successfully registers new user and creates profile with custom name', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: 'newuser@example.com',
              password: 'securePassword123',
            )).thenAnswer((_) async => mockUserCredential);

        final result = await authService.signUpWithEmailAndPassword(
          email: ' newuser@example.com ',
          password: ' securePassword123 ',
          name: ' New User ',
        );

        expect(result, equals(mockUserCredential));
        verify(() => mockAuth.createUserWithEmailAndPassword(
              email: 'newuser@example.com',
              password: 'securePassword123',
            )).called(1);
        verify(() => mockDatabaseService.ensureUserProfileExists(
              mockUser,
              customName: 'New User',
            )).called(1);
      });

      test('throws FirebaseAuthException when email is already in use', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: 'existing@example.com',
              password: 'password123',
            )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The account already exists for that email.',
        ));

        expect(
          () => authService.signUpWithEmailAndPassword(
            email: 'existing@example.com',
            password: 'password123',
            name: 'Existing User',
          ),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          )),
        );
        verifyNever(() => mockDatabaseService.ensureUserProfileExists(any(), customName: any(named: 'customName')));
      });
    });

    group('signInWithGoogle', () {
      test('successfully logs in via Google and ensures profile in database', () async {
        final mockGoogleAccount = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();

        when(() => mockGoogleAccount.authentication).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('fake-access-token');
        when(() => mockGoogleAuth.idToken).thenReturn('fake-id-token');
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);

        when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => mockUserCredential);

        final result = await authService.signInWithGoogle();

        expect(result, equals(mockUserCredential));
        expect(result?.user?.email, 'test@example.com');
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verify(() => mockAuth.signInWithCredential(any())).called(1);
        verify(() => mockDatabaseService.ensureUserProfileExists(mockUser)).called(1);
      });

      test('returns null when user cancels Google sign-in dialog', () async {
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final result = await authService.signInWithGoogle();

        expect(result, isNull);
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verifyNever(() => mockAuth.signInWithCredential(any()));
        verifyNever(() => mockDatabaseService.ensureUserProfileExists(any()));
      });

      test('throws Exception when Google sign-in fails', () async {
        when(() => mockGoogleSignIn.signIn()).thenThrow(Exception('Google Sign-In Network Error'));

        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('calls FirebaseAuth sendPasswordResetEmail with trimmed email', () async {
        when(() => mockAuth.sendPasswordResetEmail(email: 'reset@example.com'))
            .thenAnswer((_) async {});

        await authService.sendPasswordResetEmail(' reset@example.com ');

        verify(() => mockAuth.sendPasswordResetEmail(email: 'reset@example.com')).called(1);
      });

      test('throws FirebaseAuthException on invalid email', () async {
        when(() => mockAuth.sendPasswordResetEmail(email: 'invalid-email'))
            .thenThrow(FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ));

        expect(
          () => authService.sendPasswordResetEmail('invalid-email'),
          throwsA(isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          )),
        );
      });
    });

    group('signOut', () {
      test('signs out from GoogleSignIn and FirebaseAuth', () async {
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await authService.signOut();

        verify(() => mockGoogleSignIn.signOut()).called(1);
        verify(() => mockAuth.signOut()).called(1);
      });

      test('proceeds with FirebaseAuth signOut even if Google sign-out fails', () async {
        when(() => mockGoogleSignIn.signOut()).thenThrow(Exception('Google Sign-Out error'));
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await authService.signOut();

        verify(() => mockGoogleSignIn.signOut()).called(1);
        verify(() => mockAuth.signOut()).called(1);
      });
    });
  });
}
