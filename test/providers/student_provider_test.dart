import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_dev_summative_menya/core/view_state.dart';
import 'package:mobile_dev_summative_menya/models/assessment_result.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/providers/student_provider.dart';
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

  final students = [
    _s('1', 'Nawaf', SupportStatus.onTrack),
    _s('2', 'Khalid', SupportStatus.watch),
    _s('3', 'Samir', SupportStatus.needsSupport),
    _s('4', 'Jules', SupportStatus.needsSupport),
  ];

  setUp(() {
    service = MockStudentService();
    controller = StreamController<List<Student>>();
    when(() => service.streamStudents('c1'))
        .thenAnswer((_) => controller.stream);
    when(() => service.streamClassResults(any()))
        .thenAnswer((_) => const Stream.empty());
    provider = StudentProvider(service);
  });

  tearDown(() {
    provider.dispose();
    controller.close();
  });

  Future<void> loadStudents() async {
    provider.listenToClass('c1', className: 'P4 Blue');
    controller.add(students);
    await Future<void>.delayed(Duration.zero); // let the stream deliver
  }

  test('starts loading, then success when data arrives', () async {
    provider.listenToClass('c1');
    expect(provider.state, ViewState.loading);

    controller.add(students);
    await Future<void>.delayed(Duration.zero);

    expect(provider.state, ViewState.success);
    expect(provider.total, 4);
  });

  test('sets error state when stream fails', () async {
    provider.listenToClass('c1');
    controller.addError(Exception('offline'));
    await Future<void>.delayed(Duration.zero);

    expect(provider.state, ViewState.error);
    expect(provider.error, contains('offline'));
  });

  test('countOf and needsAttention', () async {
    await loadStudents();
    expect(provider.countOf(SupportStatus.needsSupport), 2);
    expect(provider.countOf(SupportStatus.watch), 1);
    expect(provider.needsAttention.map((s) => s.name), ['Samir', 'Jules']);
  });

  test('search is case-insensitive and trims', () async {
    await loadStudents();
    provider.setQuery('  KHA ');
    expect(provider.visible.map((s) => s.name), ['Khalid']);
  });

  test('filter + search combine', () async {
    await loadStudents();
    provider.setFilter(RosterFilter.needsSupport);
    expect(provider.visible.length, 2);

    provider.setQuery('sam');
    expect(provider.visible.map((s) => s.name), ['Samir']);
  });

  test('byId returns null for unknown id', () async {
    await loadStudents();
    expect(provider.byId('3')?.name, 'Samir');
    expect(provider.byId('nope'), isNull);
  });

  test('listening to the same class twice does not resubscribe', () async {
    await loadStudents();
    provider.listenToClass('c1');
    verify(() => service.streamStudents('c1')).called(1);
  });

  test('empty query shows everyone', () async {
    await loadStudents();
    provider.setQuery('');
    expect(provider.visible.length, 4);
  });

  test('watch filter shows only watch students', () async {
    await loadStudents();
    provider.setFilter(RosterFilter.watch);
    expect(provider.visible.map((s) => s.name), ['Khalid']);
  });

  test('switching back to "all" filter shows everyone again', () async {
    await loadStudents();
    provider.setFilter(RosterFilter.needsSupport);
    provider.setFilter(RosterFilter.all);
    expect(provider.visible.length, 4);
  });

  test('new data from the stream replaces the old list', () async {
    await loadStudents();
    controller.add([_s('9', 'Lina', SupportStatus.watch)]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.total, 1);
    expect(provider.all.first.name, 'Lina');
  });

  test('switching to a different class subscribes to the new class', () async {
    final otherClass = StreamController<List<Student>>();
    when(() => service.streamStudents('c2'))
        .thenAnswer((_) => otherClass.stream);

    await loadStudents();
    provider.listenToClass('c2');

    expect(provider.classId, 'c2');
    expect(controller.hasListener, isFalse); // old stream was cancelled
    verify(() => service.streamStudents('c2')).called(1);

    await otherClass.close();
  });

  test('dispose stops listening to the stream', () async {
    final p = StudentProvider(service);
    p.listenToClass('c1');
    expect(controller.hasListener, isTrue);

    p.dispose();
    expect(controller.hasListener, isFalse);
  });

  test('notifies listeners when the query changes', () async {
    await loadStudents();
    var calls = 0;
    provider.addListener(() => calls++);

    provider.setQuery('sam');
    expect(calls, 1);
  });

  test('byId before any data arrives returns null', () {
    expect(provider.byId('1'), isNull);
  });

  test('resultsFor returns only that student\'s results', () async {
    final results = StreamController<List<AssessmentResult>>();
    when(() => service.streamClassResults('c1'))
        .thenAnswer((_) => results.stream);

    provider.listenToClass('c1');
    results.add([_r('r1', '1'), _r('r2', '2'), _r('r3', '1')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.results.length, 3);
    expect(provider.resultsFor('1').map((r) => r.id), ['r1', 'r3']);
    await results.close();
  });
}

AssessmentResult _r(String id, String studentId) => AssessmentResult(
  id: id,
  schoolId: 'sch1',
  classId: 'c1',
  sessionId: 'sess1',
  studentId: studentId,
  teacherId: 't1',
  subject: Subject.reading,
  language: Language.values.first,
  level: ResponseLevel.proficient,
  durationSec: 60,
  createdAt: DateTime(2026, 11, 1),
);
