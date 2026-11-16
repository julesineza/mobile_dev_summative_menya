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
  Object? startupWarning;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 4));
    }
  } catch (error) {
    debugPrint('[Firebase Startup Warning]: $error');
    startupWarning = error;
  }

  runApp(MyApp(startupError: startupWarning));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
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
                'Firebase Notice',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.start_assessment,
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to App (Offline Mode)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
