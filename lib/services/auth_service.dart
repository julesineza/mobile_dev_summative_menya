// OWNER: Member 1. Email/password + Google sign-in, register (teacher picks a school), login, logout.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/failure.dart';
import '../core/firebase_guard.dart';
import '../core/firestore_paths.dart';
import '../models/app_user.dart';

/// Talks to Firebase Auth and the `users` collection.
/// Every public method converts Firebase errors into a [Failure].
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

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
  /// The user is signed out at the end, so they land on the login screen
  /// and sign in after verifying their email.
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
    await _auth.signOut();
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => guardFirebase(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  /// Opens Google's account chooser (with "Use another account").
  /// Returns false when the user closes it without choosing.
  /// A first-time Google user gets a profile with an empty schoolId; the app
  /// then asks them to pick a school.
  Future<bool> signInWithGoogle() => guardFirebase(() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});

    try {
      final result = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
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
    } on FirebaseAuthException catch (e) {
      const cancelled = {
        'web-context-canceled',
        'popup-closed-by-user',
        'cancelled-popup-request',
        'canceled',
      };
      if (cancelled.contains(e.code)) return false;
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

  /// Signs out of Firebase. Google sign-in now goes through Firebase itself,
  /// so there is no separate Google session to clear.
  Future<void> signOut() => guardFirebase(() => _auth.signOut());
}
