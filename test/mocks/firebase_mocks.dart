// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chat_application/services/database_service.dart';

// Firebase Auth Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockAuthCredential extends Mock implements AuthCredential {}

// Google Sign-In Mocks
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

// Cloud Firestore Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference<T extends Object?> extends Mock implements CollectionReference<T> {}
class MockDocumentReference<T extends Object?> extends Mock implements DocumentReference<T> {}
class MockDocumentSnapshot<T extends Object?> extends Mock implements DocumentSnapshot<T> {}
class MockQuerySnapshot<T extends Object?> extends Mock implements QuerySnapshot<T> {}
class MockQueryDocumentSnapshot<T extends Object?> extends Mock implements QueryDocumentSnapshot<T> {}
class MockQuery<T extends Object?> extends Mock implements Query<T> {}

// Database Service Mock
class MockDatabaseService extends Mock implements DatabaseService {}

// Fake classes for fallback values
class FakeAuthCredential extends Fake implements AuthCredential {}
class FakeUser extends Fake implements User {}
