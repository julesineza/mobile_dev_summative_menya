import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_dev_summative_menya/app_routes.dart';
import 'package:mobile_dev_summative_menya/core/support_options.dart';
import 'package:mobile_dev_summative_menya/models/assessment_result.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/models/support_plan.dart';
import 'package:mobile_dev_summative_menya/providers/auth_provider.dart';
import 'package:mobile_dev_summative_menya/providers/review_provider.dart';
import 'package:mobile_dev_summative_menya/screens/review/learner_history_screen.dart';
import 'package:mobile_dev_summative_menya/screens/review/plan_saved_screen.dart';
import 'package:mobile_dev_summative_menya/screens/review/result_saved_screen.dart';
import 'package:mobile_dev_summative_menya/screens/review/schedule_recheck_screen.dart';
import 'package:mobile_dev_summative_menya/services/auth_service.dart';
import 'package:mobile_dev_summative_menya/services/club_service.dart';
import 'package:mobile_dev_summative_menya/services/support_plan_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockPlanService extends Mock implements SupportPlanService {}

class MockClubService extends Mock implements ClubService {}

class MockAuthService extends Mock implements AuthService {}

const _student = Student(
  id: 's1',
  schoolId: 'sch1',
  classId: 'c1',
  name: 'Bruno Niyonsaba',
  rollNo: 14,
);

final _result = AssessmentResult(
  id: 'r1',
  schoolId: 'sch1',
  classId: 'c1',
  sessionId: 'a1',
  studentId: 's1',
  teacherId: 't1',
  subject: Subject.reading,
  level: ResponseLevel.struggling,
  durationSec: 30,
  createdAt: DateTime(2026, 9, 23),
  wordsPerMinute: 38,
  accuracy: 95,
);

final _mathResult = AssessmentResult(
  id: 'r2',
  schoolId: 'sch1',
  classId: 'c1',
  sessionId: 'a2',
  studentId: 's1',
  teacherId: 't1',
  subject: Subject.math,
  level: ResponseLevel.proficient,
  durationSec: 60,
  createdAt: DateTime(2026, 9, 20),
  itemsCorrect: 4,
  itemsTotal: 5,
);

SupportPlan _plan({DateTime? recheck}) => SupportPlan(
  id: 'p1',
  schoolId: 'sch1',
  classId: 'c1',
  studentId: 's1',
  resultId: 'r1',
  teacherId: 't1',
  focus: 'Practise the marked word',
  practiceType: SupportActivity.pairedReading.storageName,
  createdAt: DateTime(2026, 9, 23),
  recheckDate: recheck,
);

void main() {
  late MockPlanService service;
  late MockClubService clubs;
  late ReviewProvider provider;
  late AuthProvider auth;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(PlanStatus.active);
  });

  setUp(() {
    service = MockPlanService();
    clubs = MockClubService();
    final authService = MockAuthService();
    when(() => authService.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    auth = AuthProvider(authService);
    provider = ReviewProvider(service, clubs);

    when(() => service.getStudent('s1')).thenAnswer((_) async => _student);
    when(() => service.getResultsForStudent('s1', schoolId: 'sch1'))
        .thenAnswer((_) async => [_result, _mathResult]);
    when(() => service.getPlansForStudent('s1', schoolId: 'sch1'))
        .thenAnswer((_) async => [_plan(recheck: DateTime(2026, 9, 30))]);
    when(() => clubs.getClubs('sch1')).thenAnswer((_) async => []);
  });

  /// wraps a screen in a router so context.go, push and pop work.
  Widget app(String initial, List<RouteBase> routes) => MultiProvider(
    providers: [
      ChangeNotifierProvider<ReviewProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(initialLocation: initial, routes: routes),
    ),
  );

  Widget stub(String text) => Scaffold(body: Center(child: Text(text)));

  group('learner history', () {
    Widget history() => app('/history/s1', [
      GoRoute(
        path: AppRoutes.history,
        builder: (_, s) =>
            LearnerHistoryScreen(studentId: s.pathParameters['studentId']!),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => stub('HOME')),
    ]);

    testWidgets('lists reading and math checks with the plan under them', (
      tester,
    ) async {
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      expect(find.text('Bruno Niyonsaba'), findsOneWidget);
      expect(find.textContaining('Reading check'), findsOneWidget);
      expect(find.textContaining('Math check'), findsOneWidget);
      expect(find.text('38 correct words/min · 95% accuracy'), findsOneWidget);
      expect(find.text('4/5 correct'), findsOneWidget);
      expect(find.text('Paired reading'), findsOneWidget);
      expect(find.text('Recheck 30 Sep 2026'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      // the math check has no plan yet.
      expect(find.text('Plan support'), findsOneWidget);
    });

    testWidgets('mark rechecked changes the plan status', (tester) async {
      when(() => service.setPlanStatus('p1', PlanStatus.rechecked))
          .thenAnswer((_) async {});
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan_menu_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark rechecked'));
      await tester.pumpAndSettle();

      expect(find.text('Rechecked'), findsOneWidget);
      expect(find.text('Plan updated.'), findsOneWidget);
    });

    testWidgets('delete asks first, then removes the plan', (tester) async {
      when(() => service.deletePlan('p1')).thenAnswer((_) async {});
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan_menu_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this plan?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => service.deletePlan('p1')).called(1);
      expect(find.text('Paired reading'), findsNothing);
    });

    testWidgets('cancelling the delete dialog keeps the plan', (tester) async {
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan_menu_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => service.deletePlan(any()));
      expect(find.text('Paired reading'), findsOneWidget);
    });

    testWidgets('shows an empty message when there are no checks', (
      tester,
    ) async {
      when(() => service.getResultsForStudent('s1', schoolId: 'sch1'))
          .thenAnswer((_) async => []);
      when(() => service.getPlansForStudent('s1', schoolId: 'sch1'))
          .thenAnswer((_) async => []);
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      expect(
        find.text('No saved checks for this learner yet.'),
        findsOneWidget,
      );
    });

    testWidgets('Back to Home goes to the home route', (tester) async {
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Back to Home'));
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('shows the error and retries when loading fails', (
      tester,
    ) async {
      when(() => service.getStudent('s1')).thenAnswer((_) async => null);
      await tester.pumpWidget(history());
      await tester.pumpAndSettle();

      expect(find.text('This learner could not be found.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('schedule recheck', () {
    Widget recheck() => app('/support-plan/s1/recheck', [
      GoRoute(
        path: '/support-plan/:studentId/recheck',
        builder: (_, s) =>
            ScheduleRecheckScreen(studentId: s.pathParameters['studentId']!),
      ),
      GoRoute(
        path: '/support-plan/:studentId/saved',
        builder: (_, s) =>
            PlanSavedScreen(studentId: s.pathParameters['studentId']!),
      ),
      GoRoute(path: AppRoutes.history, builder: (_, _) => stub('HISTORY')),
      GoRoute(path: AppRoutes.home, builder: (_, _) => stub('HOME')),
    ]);

    Future<void> prepare() async {
      when(() => service.getResult('r1')).thenAnswer((_) async => _result);
      await provider.loadResult('r1');
      provider.selectActivity(SupportActivity.pairedReading);
      provider.setPlanNote('Practise the marked word');
    }

    testWidgets('one-week shortcut fills the date field', (tester) async {
      await prepare();
      await tester.pumpWidget(recheck());
      await tester.pumpAndSettle();
      expect(find.text('Pick a date'), findsOneWidget);
      expect(find.text('Paired reading'), findsOneWidget);

      await tester.tap(find.byKey(const Key('one_week_button')));
      await tester.pumpAndSettle();

      expect(provider.recheckDate, oneWeekFrom(DateTime.now()));
      expect(find.text('Pick a date'), findsNothing);
    });

    testWidgets('saving without a date shows a message and saves nothing', (
      tester,
    ) async {
      await prepare();
      await tester.pumpWidget(recheck());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save support plan'));
      await tester.pump();

      expect(
        find.text('Choose today or a later date for the recheck.'),
        findsOneWidget,
      );
      verifyNever(
        () => service.createPlan(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          studentId: any(named: 'studentId'),
          resultId: any(named: 'resultId'),
          teacherId: any(named: 'teacherId'),
          focus: any(named: 'focus'),
          practiceType: any(named: 'practiceType'),
          recheckDate: any(named: 'recheckDate'),
        ),
      );
    });

    testWidgets('saving a plan opens the "Plan saved" page', (tester) async {
      when(
        () => service.createPlan(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          studentId: any(named: 'studentId'),
          resultId: any(named: 'resultId'),
          teacherId: any(named: 'teacherId'),
          focus: any(named: 'focus'),
          practiceType: any(named: 'practiceType'),
          recheckDate: any(named: 'recheckDate'),
        ),
      ).thenAnswer((_) async => _plan(recheck: DateTime(2026, 9, 30)));
      await prepare();
      provider.useOneWeek();
      await tester.pumpWidget(recheck());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save support plan'));
      await tester.pumpAndSettle();

      expect(find.text('Support plan saved'), findsOneWidget);
      expect(find.text('Paired reading'), findsOneWidget);
      expect(find.text('Recheck 30 Sep 2026'), findsOneWidget);

      await tester.tap(find.text('View learner history'));
      await tester.pumpAndSettle();
      expect(find.text('HISTORY'), findsOneWidget);
    });
  });

  testWidgets('result saved shows the level and links to planning', (
    tester,
  ) async {
    when(() => service.getResult('r1')).thenAnswer((_) async => _result);
    await provider.loadResult('r1');
    await tester.pumpWidget(
      app('/review/r1/saved', [
        GoRoute(
          path: '/review/:resultId/saved',
          builder: (_, _) => const ResultSavedScreen(),
        ),
        GoRoute(path: AppRoutes.supportPlan, builder: (_, _) => stub('PLAN')),
        GoRoute(path: AppRoutes.home, builder: (_, _) => stub('HOME')),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Result saved'), findsOneWidget);
    expect(find.text('Struggling'), findsOneWidget);

    await tester.tap(find.text('Plan a little support'));
    await tester.pumpAndSettle();
    expect(find.text('PLAN'), findsOneWidget);
  });
}
