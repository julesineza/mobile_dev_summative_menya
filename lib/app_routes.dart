import 'package:go_router/go_router.dart';

import 'models/school_class.dart';
import 'providers/auth_provider.dart';
import 'screens/assessment/assessment_math.dart';
import 'screens/assessment/assessment_reading.dart';
import 'screens/assessment/prepare_reading.dart';
import 'screens/assessment/select_class.dart';
import 'screens/assessment/select_learners.dart';
import 'screens/assessment/setup_math_test.dart';
import 'screens/assessment/setup_reading_test.dart';
import 'screens/assessment/start_assessment.dart';
import 'screens/assessment/take_reading.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/select_school_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/settings/classes_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/students_screen.dart';
import 'screens/students/student_roster_screen.dart';
import 'screens/students/student_profile_screen.dart';
import 'screens/progress/class_progress_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/placeholder_screen.dart';

/// All route paths in one place (lib/app_routes.dart). Add yours via PR.
class AppRoutes {
  static const splash = '/splash'; // Member 1
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password'; // Member 1
  static const verifyEmail = '/verify-email'; // Member 1
  static const selectSchool = '/select-school'; // Member 1
  static const home = '/home';
  static const settings = '/settings'; // Member 1
  static const classes = '/settings/classes'; // Member 1
  static const students = '/students';
  static const studentProfile = '/students/:id';
  static const assess = '/assess';
  // Member 3's older name for the same route; kept so nothing breaks.
  // ignore: constant_identifier_names
  static const start_assessment = assess;
  static const assessReading = '/assess/reading';
  static const assessMath = '/assess/math';
  static const prepareReading = '/assess/reading/prepare';
  static const takeReading = '/assess/reading/prepare/take';
  static const selectLearners = '/assess/select-learners';
  static const selectClass = '/assess/select-class';
  static const setupReading = '/assess/setup-reading';
  static const setupMath = '/assess/setup-math';
  static const progress = '/progress';
  static const review = '/review/:resultId';
  static const supportPlan = '/support-plan/:studentId';
}

// ---------------------------------------------------------------------------
// Each member owns ONE list below, so you rarely edit the same lines.
// Replace the PlaceholderScreen with your real screen when it is ready.
// Child paths are relative to the parent, e.g. ':id' means '/students/:id'.
// ---------------------------------------------------------------------------

/// Students tab. Member 2.
List<RouteBase> get studentRoutes => [
  GoRoute(
    path: AppRoutes.students,
    builder: (_, _) => const StudentRosterScreen(),
    routes: [
      GoRoute(
        path: ':id',
        builder: (_, state) =>
            StudentProfileScreen(studentId: state.pathParameters['id']!),
      ),
    ],
  ),
];

/// Assess tab. Member 3.
List<RouteBase> get assessmentRoutes => [
  GoRoute(
    path: AppRoutes.assess,
    builder: (_, _) => const StartAssessment(),
    routes: [
      GoRoute(
        path: 'reading',
        builder: (_, _) => const AssessmentReading(),
        routes: [
          GoRoute(
            path: 'prepare',
            builder: (_, _) => const PrepareReadingPage(),
            routes: [
              GoRoute(
                path: 'take',
                builder: (_, _) => const ReadingPausedPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: 'math', builder: (_, _) => const AssessmentMath()),
      GoRoute(
        path: 'select-learners',
        builder: (_, _) => const SelectLearnersPage(),
      ),
      GoRoute(
        path: 'select-class',
        builder: (_, _) => const SelectClassesPage(),
      ),
      GoRoute(
        path: 'setup-reading',
        builder: (_, _) => const TestSetupReadingPage(),
      ),
      GoRoute(path: 'setup-math', builder: (_, _) => const TestSetupMathPage()),
    ],
  ),
];

/// Progress tab. Member 2.
List<RouteBase> get progressRoutes => [
  GoRoute(
    path: AppRoutes.progress,
    builder: (_, _) => const ClassProgressScreen(),
  ),
];

/// Full-screen routes outside the bottom navigation. Member 4.
List<RouteBase> get reviewRoutes => [
  GoRoute(
    path: AppRoutes.review,
    builder: (_, state) => PlaceholderScreen(
      'Review ${state.pathParameters['resultId']} (Member 4)',
    ),
  ),
  GoRoute(
    path: AppRoutes.supportPlan,
    builder: (_, state) => PlaceholderScreen(
      'Support plan ${state.pathParameters['studentId']} (Member 4)',
    ),
  ),
];

// ---------------------------------------------------------------------------
// Member 1: router + sign-in guard
// ---------------------------------------------------------------------------

const _publicRoutes = {
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

/// Decides where the user may be, based on the auth state.
/// Exposed for testing.
String? authRedirect(AuthProvider auth, String location) {
  // Still restoring the previous session on cold start.
  if (!auth.initialized) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  // While registering, stay on the form; the screen sends the user to login.
  if (auth.isRegistering) return null;
  if (!auth.isSignedIn) {
    return _publicRoutes.contains(location) ? null : AppRoutes.login;
  }
  if (!auth.isEmailVerified) {
    return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }
  if (auth.needsSchool) {
    return location == AppRoutes.selectSchool ? null : AppRoutes.selectSchool;
  }
  const authOnly = {
    AppRoutes.splash,
    AppRoutes.verifyEmail,
    AppRoutes.selectSchool,
  };
  if (_publicRoutes.contains(location) || authOnly.contains(location)) {
    return AppRoutes.home;
  }
  return null;
}

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (_, state) => authRedirect(auth, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectSchool,
        builder: (_, _) => const SelectSchoolScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'classes', builder: (_, _) => const ClassesScreen()),
          GoRoute(
            path: 'classes/:classId/students',
            builder: (_, state) =>
                StudentsScreen(schoolClass: state.extra! as SchoolClass),
          ),
        ],
      ),
      ...reviewRoutes,
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: studentRoutes),
          StatefulShellBranch(routes: assessmentRoutes),
          StatefulShellBranch(routes: progressRoutes),
        ],
      ),
    ],
  );
}
