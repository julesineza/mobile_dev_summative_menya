import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/club_service.dart';
import '../services/dashboard_service.dart';
import '../services/preferences_service.dart';
import '../services/school_class_service.dart';
import '../services/student_service.dart';
import '../services/support_plan_service.dart';
import 'assessment_provider.dart';
import 'auth_provider.dart';
import 'class_provider.dart';
import 'dashboard_provider.dart';
import 'review_provider.dart';
import 'school_provider.dart';
import 'settings_provider.dart';
import 'student_provider.dart';

/// Builds the full provider list, wiring both [SharedPreferences] and [PreferencesService]
/// into [SettingsProvider] and keeping [AssessmentProvider] on the selected class.
///
/// Call this from [main.dart] after both preference services have been initialized.
List<SingleChildWidget> buildProviders(PreferencesService prefs) => [
  ...authProviders,
  ...studentProviders,
  ChangeNotifierProvider<SettingsProvider>(
    create: (context) => SettingsProvider(prefs)..attachService(prefs),
  ),
  // Assessment (Member 3): the active class always comes from the teacher's
  // real classes in ClassProvider. No class -> no fallback, the screens ask
  // the teacher to create one.
  ChangeNotifierProxyProvider<ClassProvider, AssessmentProvider>(
    create: (_) => AssessmentProvider(),
    update: (_, classes, previous) {
      final provider = previous ?? AssessmentProvider();
      final selected = classes.selectedClass;
      if (selected != null) {
        provider.syncFromClass(
          id: selected.id,
          name: selected.name,
          schoolId: selected.schoolId,
          grade: selected.grade,
        );
      } else {
        provider.clearClass();
      }
      return provider;
    },
  ),
  ...reviewProviders,
];

/// Legacy provider list for backward compatibility (uses SharedPreferences only).
/// Every feature's providers are registered here, wrapped around MaterialApp in main.dart.
/// Keep one list per feature so members rarely edit the same lines.
List<SingleChildWidget> get appProviders => [
  ...authProviders,
  ...studentProviders,
  ...assessmentProviders,
  ...reviewProviders,
];

// ── Per-feature provider lists (kept separate so each member rarely conflicts) ──

/// Auth providers — owned by Member 1.
List<SingleChildWidget> get authProviders => [
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

/// Student / class analytics providers — owned by Member 2.
List<SingleChildWidget> get studentProviders => [
  ChangeNotifierProxyProvider<ClassProvider, StudentProvider>(
    create: (_) => StudentProvider(StudentService()),
    update: (_, classes, previous) {
      final provider = previous!;
      final selected = classes.selectedClass;
      if (selected != null) {
        provider.listenToClass(
          selected.id,
          schoolId: selected.schoolId,
          className: selected.name,
        );
      } else {
        provider.watchClass(null);
      }
      return provider;
    },
  ),
];

/// Assessment providers — owned by Member 3.
List<SingleChildWidget> get assessmentProviders => [];

/// Post-assessment review providers — owned by Member 4.
List<SingleChildWidget> get reviewProviders => [
  ChangeNotifierProvider<ReviewProvider>(
    create: (_) => ReviewProvider(SupportPlanService(), ClubService()),
  ),
];
