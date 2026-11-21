import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'failure.dart';

/// Runs [run] and turns Firebase / Google exceptions into a [Failure]
/// whose message can be shown directly in a SnackBar.
Future<T> guardFirebase<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on FirebaseAuthException catch (e) {
    throw Failure(_authMessage(e));
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      throw const Failure('You do not have permission to do that.');
    }
    throw const Failure(
      'Could not reach the database. Check your connection and try again.',
    );
  } on GoogleSignInException {
    throw const Failure('Google sign-in failed. Please try again.');
  }
}

String _authMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address looks invalid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account already exists with that email.';
    case 'weak-password':
      return 'Choose a stronger password (8+ characters).';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';
    case 'account-exists-with-different-credential':
      return 'This email is already registered with a different sign-in method.';
    default:
      return e.message ?? 'Something went wrong. Please try again.';
  }
}
