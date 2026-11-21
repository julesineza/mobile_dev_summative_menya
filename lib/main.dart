import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'core/constants/app_theme.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'providers/settings_provider.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load SharedPreferences (theme, active class, timer mode, etc.) before the UI starts.
  final prefs = await PreferencesService.init();

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
    // Firebase failure does not block the app — preferences still load normally.
  }

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final PreferencesService prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProviders(prefs),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Menya',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            initialRoute: AppRoutes.start_assessment,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
