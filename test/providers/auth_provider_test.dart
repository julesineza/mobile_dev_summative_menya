import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/failure.dart';
import 'package:mobile_dev_summative_menya/core/view_state.dart';
import 'package:mobile_dev_summative_menya/providers/auth_provider.dart';
import 'package:mobile_dev_summative_menya/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService service;
  late StreamController<User?> authEvents;
  late AuthProvider provider;

  setUp(() {
    service = MockAuthService();
    authEvents = StreamController<User?>();
    when(() => service.authStateChanges()).thenAnswer((_) => authEvents.stream);
    provider = AuthProvider(service);
  });

  tearDown(() async {
    provider.dispose();
    await authEvents.close();
  });

  test('is not initialized until Firebase reports the session', () async {
    expect(provider.initialized, isFalse);

    authEvents.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(provider.initialized, isTrue);
    expect(provider.isSignedIn, isFalse);
  });

  test('signInWithEmail returns true and goes to success', () async {
    when(
      () => service.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    final ok = await provider.signInWithEmail('a@b.com', 'secret123');

    expect(ok, isTrue);
    expect(provider.state, ViewState.success);
    expect(provider.errorMessage, isNull);
  });

  test('signInWithEmail failure keeps the friendly message', () async {
    when(
      () => service.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => throw const Failure('Incorrect email or password.'),
    );

    final ok = await provider.signInWithEmail('a@b.com', 'wrong');

    expect(ok, isFalse);
    expect(provider.state, ViewState.error);
    expect(provider.errorMessage, 'Incorrect email or password.');
  });

  test('cancelled Google sign-in is not an error', () async {
    when(() => service.signInWithGoogle()).thenAnswer((_) async => false);

    final ok = await provider.signInWithGoogle();

    expect(ok, isFalse);
    expect(provider.errorMessage, isNull);
  });
}
