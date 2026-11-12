import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'core/constants/app_theme.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (error) {
    startupError = error;
  }
  runApp(MyApp(startupError: startupError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: 'Menya',
        theme: AppTheme.light,
        home: StartupErrorPage(error: startupError!),
      );
    }
    return MultiProvider(
      providers: appProviders,
      child: MaterialApp(
        title: 'Menya',
        theme: AppTheme.light,
        initialRoute: AppRoutes.start_assessment,
        routes: AppRoutes.routes,
      ),
    );
  }
}

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Firebase could not start',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              const Text(
                'Enable Anonymous sign-in in Firebase Console, then restart the app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
