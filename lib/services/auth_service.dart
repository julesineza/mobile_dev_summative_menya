// OWNER: Member 1. Email/password + Google sign-in, register (teacher picks a school), login, logout.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

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
    try {
      final UserCredential result;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        result = await _auth.signInWithPopup(provider);
      } else {
        // Native Google sign-in on Android/iOS. The browser-based
        // signInWithProvider flow can hang after "Next" on mobile.
        await _initGoogle();
        final GoogleSignInAccount account;
        try {
          account = await GoogleSignIn.instance.authenticate();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) return false;
          rethrow;
        }
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          throw const Failure('Google sign-in failed. Please try again.');
        }
        result = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }
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

  /// Signs out of Firebase and, on mobile, the native Google session so the
  /// account chooser shows again next time.
  Future<void> signOut() => guardFirebase(() async {
    if (!kIsWeb && _googleReady) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  });

  // OAuth client IDs from google-services.json (Firebase project 879135523749).
  static const _webClientId =
      '879135523749-77i6eoogo1jeb9ipk9769qqutlmbulf3.apps.googleusercontent.com';
  static const _iosClientId =
      '879135523749-iuts2qdkr1ief2s8lc61128o5ig2gthg.apps.googleusercontent.com';

  static bool _googleReady = false;

  /// GoogleSignIn.instance must be initialized exactly once before use.
  static Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _iosClientId
          : null,
      serverClientId: _webClientId,
    );
    _googleReady = true;
  }
}
