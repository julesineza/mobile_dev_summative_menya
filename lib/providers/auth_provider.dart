// OWNER: Member 1.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/view_state.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Session state for the whole app: who is signed in, their profile, and the
/// loading / error state of every auth action. The router listens to this.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _authSub = _service.authStateChanges().listen(
      _onAuthChanged,
      onError: (_) => _onAuthChanged(null),
    );
  }

  final AuthService _service;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? _firebaseUser;
  AppUser? _profile;
  bool _initialized = false;
  bool _registering = false;

  ViewState state = ViewState.idle;
  String? errorMessage;

  /// False until Firebase has told us whether someone is already signed in.
  bool get initialized => _initialized;
  User? get firebaseUser => _firebaseUser;
  AppUser? get profile => _profile;
  bool get isSignedIn => _firebaseUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;
  bool get isLoading => state == ViewState.loading;

  /// True while a new account is being created, so the router does not
  /// redirect before the register screen sends the user to login.
  bool get isRegistering => _registering;

  /// Google users start with an empty school and must pick one.
  bool get needsSchool => _profile != null && _profile!.schoolId.isEmpty;

  void _onAuthChanged(User? user) {
    _firebaseUser = user;
    _initialized = true;
    _profileSub?.cancel();
    _profileSub = null;
    _profile = null;

    if (user != null) {
      _profileSub = _service
          .watchProfile(user.uid)
          .listen(
            (profile) {
              _profile = profile;
              notifyListeners();
            },
            onError: (_) {
              _profile = null;
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      state = ViewState.success;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      state = ViewState.error;
      errorMessage = e.message;
    } catch (e) {
      debugPrint('Auth error: $e');
      state = ViewState.error;
      errorMessage = 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _service.signInWithEmail(email: email, password: password));

  /// Creates the account, sends the verification email and signs out.
  /// The caller then sends the user to the login screen.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String schoolId,
  }) async {
    _registering = true;
    final ok = await _run(
      () => _service.registerWithEmail(
        name: name,
        email: email,
        password: password,
        schoolId: schoolId,
      ),
    );
    _registering = false;
    notifyListeners();
    return ok;
  }

  /// Returns false when cancelled (errorMessage stays null) or on error.
  Future<bool> signInWithGoogle() async {
    var signedIn = false;
    final ok = await _run(() async {
      signedIn = await _service.signInWithGoogle();
    });
    return ok && signedIn;
  }

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _service.sendPasswordReset(email));

  Future<bool> resendVerification() => _run(_service.sendEmailVerification);

  /// Reloads the user and returns whether the email is now verified.
  Future<bool> refreshVerification() async {
    final ok = await _run(_service.reloadUser);
    _firebaseUser = _service.currentUser;
    notifyListeners(); // lets the router re-check the verified flag
    return ok && isEmailVerified;
  }

  Future<bool> updateProfile({String? name, String? schoolId}) {
    final uid = _firebaseUser?.uid;
    if (uid == null) return Future.value(false);
    return _run(
      () => _service.updateProfile(uid, name: name, schoolId: schoolId),
    );
  }

  Future<bool> signOut() => _run(_service.signOut);

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
