import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

/// Service responsible for managing user authentication with Firebase and Google Sign-In.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final DatabaseService _databaseService;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    DatabaseService? databaseService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _databaseService = databaseService ?? DatabaseService();

  /// Gets the currently authenticated user, or null if unauthenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Email and Password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (userCredential.user != null) {
      await _databaseService.ensureUserProfileExists(userCredential.user!);
    }

    return userCredential;
  }

  /// Sign up with Email and Password and initialise the user profile.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (userCredential.user != null) {
      await _databaseService.ensureUserProfileExists(
        userCredential.user!,
        customName: name?.trim(),
      );
    }

    return userCredential;
  }

  /// Sign in with Google Auth flow.
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // User cancelled the sign-in flow
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await _databaseService.ensureUserProfileExists(user);
    }

    return userCredential;
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out from Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('AuthService: Error during Google Sign-Out: $e');
    }
    await _auth.signOut();
  }
}
