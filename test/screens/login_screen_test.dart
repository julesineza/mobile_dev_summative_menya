import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/theme/app_theme.dart';
import 'package:mobile_dev_summative_menya/providers/auth_provider.dart';
import 'package:mobile_dev_summative_menya/providers/settings_provider.dart';
import 'package:mobile_dev_summative_menya/screens/auth/login_screen.dart';
import 'package:mobile_dev_summative_menya/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

Future<void> pumpLogin(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final service = MockAuthService();
  when(() => service.authStateChanges())
      .thenAnswer((_) => const Stream<User?>.empty());

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(service)),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    ),
  );
}

void main() {
  testWidgets('shows validation messages when the form is empty', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('rejects a malformed email', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}
