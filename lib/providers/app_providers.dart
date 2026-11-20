import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/school_class_service.dart';
import 'auth_provider.dart';
import 'class_provider.dart';
import 'dashboard_provider.dart';
import 'school_provider.dart';
import 'settings_provider.dart';

/// Every feature's providers are registered here, wrapped around MaterialApp in main.dart.
/// Keep one list per feature so members rarely edit the same lines.
/// main.dart provides a SharedPreferences instance above this list.
List<SingleChildWidget> get appProviders => [
  ...authProviders,
  ...studentProviders,
  ...assessmentProviders,
  ...reviewProviders,
];

// Replace these empty lists with real ChangeNotifierProviders as you build.
// Example: ChangeNotifierProvider(create: (_) => AssessmentProvider(repo))
List<SingleChildWidget> get authProviders => [
  // Member 1
  ChangeNotifierProvider<SettingsProvider>(
    create: (context) => SettingsProvider(context.read<SharedPreferences>()),
  ),
  Provider<AuthService>(create: (_) => AuthService()),
  ChangeNotifierProvider<AuthProvider>(
    create: (context) => AuthProvider(context.read<AuthService>()),
  ),
  ChangeNotifierProvider<SchoolProvider>(
    create: (_) => SchoolProvider(SchoolClassService()),
  ),
  ChangeNotifierProxyProvider2<AuthProvider, SettingsProvider, ClassProvider>(
    create: (_) => ClassProvider(SchoolClassService()),
    update: (_, auth, settings, previous) => previous!
      ..configure(
        uid: auth.isSignedIn && auth.isEmailVerified
            ? auth.firebaseUser!.uid
            : null,
        settings: settings,
      ),
  ),
  ChangeNotifierProxyProvider<ClassProvider, DashboardProvider>(
    create: (_) => DashboardProvider(DashboardService()),
    update: (_, classes, previous) =>
        previous!..watchClass(classes.selectedClass),
  ),
];
List<SingleChildWidget> get studentProviders => []; // Member 2
List<SingleChildWidget> get assessmentProviders => []; // Member 3
List<SingleChildWidget> get reviewProviders => []; // Member 4
