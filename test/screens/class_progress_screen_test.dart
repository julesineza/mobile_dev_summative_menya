import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/providers/student_provider.dart';
import 'package:mobile_dev_summative_menya/screens/progress/class_progress_screen.dart';
import 'package:mobile_dev_summative_menya/services/student_service.dart';

class MockStudentService extends Mock implements StudentService {}

Student _s(String id, String name, SupportStatus status) => Student(
  id: id,
  schoolId: 'sch1',
  classId: 'c1',
  name: name,
  rollNo: 1,
  status: status,
);

void main() {
  late MockStudentService service;
  late StreamController<List<Student>> controller;
  late StudentProvider provider;

  setUp(() {
    service = MockStudentService();
    controller = StreamController<List<Student>>();
    when(() => service.streamStudents('c1'))
        .thenAnswer((_) => controller.stream);
    provider = StudentProvider(service);
  });

  tearDown(() => controller.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall screen so the whole ListView is built (it builds lazily).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>.value(
        value: provider,
        child: const MaterialApp(home: ClassProgressScreen()),
      ),
    );
    await tester.pump(); // let stream data arrive and rebuild
  }

  testWidgets('shows a spinner while loading', (tester) async {
    provider.listenToClass('c1'); // no data sent yet
    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows class counts and students needing attention', (
    tester,
  ) async {
    provider.listenToClass('c1', className: 'P4 Blue');
    controller.add([
      _s('1', 'Nawaf', SupportStatus.onTrack),
      _s('2', 'Khalid', SupportStatus.watch),
      _s('3', 'Samir', SupportStatus.needsSupport),
      _s('4', 'Jules', SupportStatus.needsSupport),
    ]);
    await pumpScreen(tester);

    expect(find.text('4 students · P4 Blue'), findsOneWidget);
    expect(find.text('On track (1)'), findsOneWidget);
    expect(find.text('Watch (1)'), findsOneWidget);
    expect(find.text('Support (2)'), findsOneWidget);

    expect(find.text('Samir'), findsOneWidget);
    expect(find.text('Jules'), findsOneWidget);
    expect(find.text('Nawaf'), findsNothing); // on track → not flagged
  });

  testWidgets('shows empty message when nobody needs support', (tester) async {
    provider.listenToClass('c1');
    controller.add([_s('1', 'Nawaf', SupportStatus.onTrack)]);
    await pumpScreen(tester);

    expect(find.text('No learners flagged right now.'), findsOneWidget);
  });

  testWidgets('subject bars show "No data yet" without results', (
    tester,
  ) async {
    provider.listenToClass('c1');
    controller.add([]);
    await pumpScreen(tester);

    expect(find.text('No data yet'), findsNWidgets(2));
  });
}
