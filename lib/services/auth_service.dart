// OWNER: Member 1. Email/password + Google sign-in, register (teacher picks a school), login, logout.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/failure.dart';
import '../core/firebase_guard.dart';
import '../core/firestore_paths.dart';
import '../models/app_user.dart';

/// Talks to Firebase Auth, Google Sign-In and the `users` collection.
/// Every public method converts Firebase errors into a [Failure].
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  Future<void>? _googleInit;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  User? get currentUser => _auth.currentUser;

  /// Emits on sign-in, sign-out and whenever the user is reloaded.
  Stream<User?> authStateChanges() => _auth.userChanges();

  /// READ: live teacher profile (users/{uid}). Emits null if it does not exist yet.
  Stream<AppUser?> watchProfile(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);

  /// CREATE: auth account + users/{uid} profile + verification email.
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String schoolId,
  }) => guardFirebase(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name);
    final profile = AppUser(
      uid: user.uid,
      name: name,
      email: email,
      schoolId: schoolId,
    );
    await _users.doc(user.uid).set(profile.toMap());
    await user.sendEmailVerification();
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => guardFirebase(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  /// Returns false when the user closes the Google account picker.
  /// A first-time Google user gets a profile with an empty schoolId; the app
  /// then asks them to pick a school.
  Future<bool> signInWithGoogle() => guardFirebase(() async {
    _googleInit ??= _google.initialize();
    await _googleInit;
    try {
      final account = await _google.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;

      final doc = _users.doc(user.uid);
      if (!(await doc.get()).exists) {
        final profile = AppUser(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          schoolId: '',
        );
        await doc.set(profile.toMap());
      }
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  });

  Future<void> sendPasswordReset(String email) =>
      guardFirebase(() => _auth.sendPasswordResetEmail(email: email));

  Future<void> sendEmailVerification() =>
      guardFirebase(() async => _auth.currentUser?.sendEmailVerification());

  /// Re-reads the user from Firebase so emailVerified is up to date.
  Future<void> reloadUser() =>
      guardFirebase(() async => _auth.currentUser?.reload());

  /// UPDATE: only the fields that are passed are changed.
  Future<void> updateProfile(String uid, {String? name, String? schoolId}) {
    final changes = <String, dynamic>{'name': ?name, 'schoolId': ?schoolId};
    if (changes.isEmpty) {
      throw const Failure('Nothing to update.');
    }
    return guardFirebase(() => _users.doc(uid).update(changes));
  }

  Future<void> signOut() => guardFirebase(() async {
    _googleInit ??= _google.initialize();
    await _googleInit;
    await _google.signOut();
    await _auth.signOut();
  });
}