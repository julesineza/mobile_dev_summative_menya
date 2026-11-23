import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_dev_summative_menya/core/failure.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/services/student_service.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDoc extends Mock implements DocumentReference<Map<String, dynamic>> {}

const _student = Student(
  id: '',
  schoolId: 'sch1',
  classId: 'c1',
  name: 'Aline',
  rollNo: 7,
  status: SupportStatus.onTrack,
);

void main() {
  late MockCollection col;
  late MockDoc doc;
  late StudentService service;

  // A server reply that never arrives, like being offline.
  final offline = Completer<Never>().future;

  setUp(() {
    final db = MockFirestore();
    col = MockCollection();
    doc = MockDoc();
    when(() => db.collection('students')).thenReturn(col);
    when(() => col.doc(any())).thenReturn(doc);
    when(() => col.doc()).thenReturn(doc);
    when(() => col.add(any())).thenAnswer((_) => offline);
    when(() => doc.set(any())).thenAnswer((_) => offline);
    when(() => doc.delete()).thenAnswer((_) => offline);
    service = StudentService(db: db);
  });

  test('addStudent finishes without waiting for the server', () async {
    await service.addStudent(_student).timeout(const Duration(seconds: 1));
    verify(() => doc.set(_student.toMap())).called(1);
  });

  test('deleteStudent finishes without waiting for the server', () async {
    await service.deleteStudent('s1').timeout(const Duration(seconds: 1));
    verify(() => col.doc('s1')).called(1);
    verify(() => doc.delete()).called(1);
  });

  // The server says no, e.g. the Firestore rules block the write.
  final denied = FirebaseException(
    plugin: 'cloud_firestore',
    code: 'permission-denied',
  );

  test('addStudent reports a rejected write through onError', () async {
    when(() => doc.set(any())).thenAnswer((_) async => throw denied);
    final failure = Completer<Failure>();

    await service.addStudent(_student, onError: failure.complete);

    final f = await failure.future.timeout(const Duration(seconds: 1));
    expect(f.message, 'You do not have permission to do that.');
  });

  test('deleteStudent reports a rejected write through onError', () async {
    when(() => doc.delete()).thenAnswer((_) async => throw denied);
    final failure = Completer<Failure>();

    await service.deleteStudent('s1', onError: failure.complete);

    final f = await failure.future.timeout(const Duration(seconds: 1));
    expect(f.message, 'You do not have permission to do that.');
  });
}
