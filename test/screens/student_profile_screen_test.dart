import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mobile_dev_summative_menya/models/assessment_result.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/providers/student_provider.dart';
import 'package:mobile_dev_summative_menya/screens/students/student_profile_screen.dart';
import 'package:mobile_dev_summative_menya/services/student_service.dart';

class MockStudentService extends Mock implements StudentService {}

const _samir = Student(
  id: '3',
  schoolId: 'sch1',
  classId: 'c1',
  name: 'Samir',
  rollNo: 12,
  status: SupportStatus.needsSupport,
);

AssessmentResult _r(
  String id,
  Subject subject,
  ResponseLevel level,
  double accuracy,
  DateTime createdAt, {
  String studentId = '3',
}) => AssessmentResult(
  id: id,
  schoolId: 'sch1',
  classId: 'c1',
  sessionId: 'sess1',
  studentId: studentId,
  teacherId: 't1',
  subject: subject,
  level: level,
  durationSec: 60,
  createdAt: createdAt,
  accuracy: accuracy,
);

void main() {
  late MockStudentService service;
  late StreamController<List<Student>> students;
  late StreamController<List<AssessmentResult>> results;
  late StudentProvider provider;

  setUp(() {
    service = MockStudentService();
    students = StreamController<List<Student>>();
    results = StreamController<List<AssessmentResult>>();
    when(() => service.streamStudents('c1'))
        .thenAnswer((_) => students.stream);
    when(() => service.streamClassResults('c1'))
        .thenAnswer((_) => results.stream);
    provider = StudentProvider(service);
  });

  tearDown(() {
    students.close();
    results.close();
  });

  Future<void> pumpScreen(WidgetTester tester, {String id = '3'}) async {
    // Tall screen so the whole ListView is built (it builds lazily).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>.value(
        value: provider,
        child: MaterialApp(home: StudentProfileScreen(studentId: id)),
      ),
    );
    await tester.pump(); // let stream data arrive and rebuild
  }

  testWidgets('shows a spinner while the roster is loading', (tester) async {
    provider.listenToClass('c1'); // no data sent yet
    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows "Student not found." for an unknown id', (tester) async {
    provider.listenToClass('c1');
    students.add([_samir]);
    await pumpScreen(tester, id: 'nope');

    expect(find.text('Student not found.'), findsOneWidget);
  });

  testWidgets('shows name, class, roll number and status', (tester) async {
    provider.listenToClass('c1', className: 'P4 Blue');
    students.add([_samir]);
    await pumpScreen(tester);

    expect(find.text('Samir'), findsOneWidget);
    expect(find.text('Class P4 Blue • Roll No. 12'), findsOneWidget);
    expect(find.text('NEEDS SUPPORT'), findsOneWidget);
    expect(find.text('Start Quick Check Now'), findsOneWidget);
  });

  testWidgets('with no results, both subjects say "Not assessed yet"', (
    tester,
  ) async {
    provider.listenToClass('c1');
    students.add([_samir]);
    await pumpScreen(tester);

    expect(find.text('Not assessed yet'), findsNWidgets(2));
    expect(find.text('No checks yet.'), findsOneWidget);
  });

  testWidgets('subject cards show latest level, trend and score', (
    tester,
  ) async {
    provider.listenToClass('c1');
    students.add([_samir]);
    results.add([
      // Reading went 60% → 80%: improving.
      _r('r1', Subject.reading, ResponseLevel.struggling, 60,
          DateTime(2026, 11, 1)),
      _r('r2', Subject.reading, ResponseLevel.developing, 80,
          DateTime(2026, 11, 10)),
      // Only one math check: first check.
      _r('m1', Subject.math, ResponseLevel.proficient, 90,
          DateTime(2026, 11, 5)),
      // Another student's result must not show up.
      _r('x1', Subject.math, ResponseLevel.struggling, 10,
          DateTime(2026, 11, 6), studentId: '9'),
    ]);
    await pumpScreen(tester);

    expect(find.text('Level: Developing • Improving'), findsOneWidget);
    expect(find.text('▲ 80%'), findsOneWidget);
    expect(find.text('Level: Proficient • First check'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('10%'), findsNothing);
  });

  testWidgets('a lower score shows as declining', (tester) async {
    provider.listenToClass('c1');
    students.add([_samir]);
    results.add([
      _r('r1', Subject.reading, ResponseLevel.proficient, 90,
          DateTime(2026, 11, 1)),
      _r('r2', Subject.reading, ResponseLevel.struggling, 40,
          DateTime(2026, 11, 10)),
    ]);
    await pumpScreen(tester);

    expect(find.text('Level: Struggling • Declining'), findsOneWidget);
    expect(find.text('▼ 40%'), findsOneWidget);
  });

  testWidgets('history lists every check, newest first', (tester) async {
    provider.listenToClass('c1');
    students.add([_samir]);
    results.add([
      _r('r1', Subject.reading, ResponseLevel.struggling, 60,
          DateTime(2026, 11, 1)),
      _r('m1', Subject.math, ResponseLevel.proficient, 90,
          DateTime(2026, 11, 5)),
    ]);
    await pumpScreen(tester);

    expect(find.text('No checks yet.'), findsNothing);
    final math = find.text('Proficient (Nov 5)');
    final reading = find.text('Struggling (Nov 1)');
    expect(math, findsOneWidget);
    expect(reading, findsOneWidget);
    // Newest (math, Nov 5) is above the older reading check.
    expect(
      tester.getTopLeft(math).dy,
      lessThan(tester.getTopLeft(reading).dy),
    );
  });

  testWidgets('shows a banner when results fail to load', (tester) async {
    provider.listenToClass('c1');
    students.add([_samir]);
    results.addError(Exception('denied'));
    await pumpScreen(tester);

    expect(find.text('Could not load assessment results.'), findsOneWidget);
    // The profile itself still shows.
    expect(find.text('Samir'), findsOneWidget);
  });
}
