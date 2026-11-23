import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mobile_dev_summative_menya/core/failure.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/providers/student_provider.dart';
import 'package:mobile_dev_summative_menya/screens/students/student_roster_screen.dart';
import 'package:mobile_dev_summative_menya/services/student_service.dart';

class MockStudentService extends Mock implements StudentService {}

class FakeStudent extends Fake implements Student {}

Student _s(String id, String name, SupportStatus status) => Student(
  id: id,
  schoolId: 'sch1',
  classId: 'c1',
  name: name,
  rollNo: 1,
  status: status,
);

final _students = [
  _s('1', 'Nawaf', SupportStatus.onTrack),
  _s('2', 'Khalid', SupportStatus.watch),
  _s('3', 'Samir', SupportStatus.needsSupport),
  _s('4', 'Jules', SupportStatus.needsSupport),
];

void main() {
  late MockStudentService service;
  late StreamController<List<Student>> controller;
  late StudentProvider provider;

  setUpAll(() => registerFallbackValue(FakeStudent()));

  setUp(() {
    service = MockStudentService();
    controller = StreamController<List<Student>>();
    when(() => service.streamStudents('c1'))
        .thenAnswer((_) => controller.stream);
    when(() => service.streamClassResults(any()))
        .thenAnswer((_) => const Stream.empty());
    provider = StudentProvider(service);
  });

  // Don't await close(): it never completes if nothing listened to the
  // stream (the "No class selected" test never subscribes).
  tearDown(() {
    controller.close();
  });

  // Uses a real GoRouter so tapping a row can navigate to the profile.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const StudentRosterScreen()),
        GoRoute(
          path: '/students/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Profile ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>.value(
        value: provider,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(); // let stream data arrive and rebuild
  }

  Future<void> loadStudents(WidgetTester tester) async {
    provider.listenToClass('c1', className: 'P4 Blue');
    controller.add(_students);
    await pumpScreen(tester);
  }

  testWidgets('shows "No class selected." before any class is chosen', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('No class selected.'), findsOneWidget);
  });

  testWidgets('shows a spinner while loading', (tester) async {
    provider.listenToClass('c1'); // no data sent yet
    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a friendly message when loading fails', (tester) async {
    provider.listenToClass('c1');
    controller.addError(Exception('offline'));
    await pumpScreen(tester);

    expect(
      find.text('Could not load students. Check your connection.'),
      findsOneWidget,
    );
  });

  testWidgets('lists every student with the class name', (tester) async {
    await loadStudents(tester);

    for (final name in ['Nawaf', 'Khalid', 'Samir', 'Jules']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.textContaining('Class P4 Blue'), findsNWidgets(4));
  });

  testWidgets('filter pills show the right counts', (tester) async {
    await loadStudents(tester);

    expect(find.text('All (4)'), findsOneWidget);
    expect(find.text('Needs Support (2)'), findsOneWidget);
    expect(find.text('Watch (1)'), findsOneWidget);
  });

  testWidgets('tapping "Needs Support" shows only those students', (
    tester,
  ) async {
    await loadStudents(tester);

    await tester.tap(find.text('Needs Support (2)'));
    await tester.pump();

    expect(find.text('Samir'), findsOneWidget);
    expect(find.text('Jules'), findsOneWidget);
    expect(find.text('Nawaf'), findsNothing);
    expect(find.text('Khalid'), findsNothing);

    // Back to everyone.
    await tester.tap(find.text('All (4)'));
    await tester.pump();
    expect(find.text('Nawaf'), findsOneWidget);
  });

  testWidgets('tapping "Watch" shows only watch students', (tester) async {
    await loadStudents(tester);

    await tester.tap(find.text('Watch (1)'));
    await tester.pump();

    expect(find.text('Khalid'), findsOneWidget);
    expect(find.text('Samir'), findsNothing);
  });

  testWidgets('typing in search narrows the list', (tester) async {
    await loadStudents(tester);

    await tester.enterText(find.byType(TextField), 'sam');
    await tester.pump();

    expect(find.text('Samir'), findsOneWidget);
    expect(find.text('Nawaf'), findsNothing);
  });

  testWidgets('search with no match shows "No students match."', (
    tester,
  ) async {
    await loadStudents(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('No students match.'), findsOneWidget);
  });

  testWidgets('a failed save shows a banner the user can dismiss', (
    tester,
  ) async {
    when(
      () => service.deleteStudent(any(), onError: any(named: 'onError')),
    ).thenAnswer((inv) async {
      final onError = inv.namedArguments[#onError] as void Function(Failure)?;
      onError?.call(const Failure('You do not have permission to do that.'));
    });
    await loadStudents(tester);

    await provider.deleteStudent('3');
    await tester.pump();

    const message =
        'Could not remove Samir. You do not have permission to do that.';
    expect(find.text(message), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    expect(find.text(message), findsNothing);
  });

  testWidgets('tapping a student opens their profile', (tester) async {
    await loadStudents(tester);

    await tester.tap(find.text('Samir'));
    await tester.pumpAndSettle();

    expect(find.text('Profile 3'), findsOneWidget);
  });
}
