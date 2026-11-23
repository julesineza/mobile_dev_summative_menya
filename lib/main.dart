import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app_routes.dart';
import 'core/constants/app_theme.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load both SharedPreferences and PreferencesService for compatibility
  final sharedPrefs = await SharedPreferences.getInstance();
  final prefs = await PreferencesService.init();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('[Firebase Startup Warning]: $error');
    // Firebase failure does not block the app — preferences still load normally.
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sharedPrefs),
        ...buildProviders(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Created once so navigation state survives rebuilds.
    _router = createRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (s) => s.themeMode,
    );
    return MaterialApp.router(
      title: 'Menya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
