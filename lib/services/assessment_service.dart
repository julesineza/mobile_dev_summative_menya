import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/firestore_paths.dart';
import '../models/assessment_result.dart';
import '../models/assessment_session.dart';
import '../models/assessment_test.dart';
import '../models/enums.dart';
import '../models/student.dart';

class AssessmentService {
  AssessmentService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<AssessmentTest?> getTest({
    required String schoolId,
    required Subject subject,
    required int grade,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final snapshot = await firestore
          .collection(FirestorePaths.tests)
          .where('schoolId', isEqualTo: schoolId)
          .where('subject', isEqualTo: subject.name)
          .where('grade', isEqualTo: grade)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isEmpty) return null;
      return AssessmentTest.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('[AssessmentService] getTest error/timeout ($e), using fallback test');
      return null;
    }
  }

  Future<List<Student>> getStudents({required String classId}) async {
    final firestore = _firestore;
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore
          .collection(FirestorePaths.students)
          .where('classId', isEqualTo: classId)
          .orderBy('rollNo')
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.map(Student.fromFirestore).toList();
    } catch (e) {
      debugPrint('[AssessmentService] getStudents error/timeout ($e), using local learners');
      return const [];
    }
  }

  Future<AssessmentSession> createSession({
    required String schoolId,
    required String classId,
    required String teacherId,
    required AssessmentTest test,
    required List<String> studentIds,
  }) async {
    final effectiveTeacherId = _resolveTeacherId(teacherId);
    final firestore = _firestore;
    final sessionId = firestore != null
        ? firestore.collection(FirestorePaths.assessments).doc().id
        : 'session-${DateTime.now().microsecondsSinceEpoch}';

    debugPrint(
      '[AssessmentService] createSession start '
      'session=$sessionId students=${studentIds.length}',
    );
    final session = AssessmentSession(
      id: sessionId,
      schoolId: schoolId,
      classId: classId,
      teacherId: effectiveTeacherId,
      testId: test.id,
      subject: test.subject,
      language: test.language,
      studentIds: studentIds,
      createdAt: DateTime.now(),
    );

    if (firestore != null) {
      try {
        await firestore
            .collection(FirestorePaths.assessments)
            .doc(sessionId)
            .set(session.toMap())
            .timeout(const Duration(seconds: 5));
        debugPrint(
          '[AssessmentService] createSession success session=$sessionId',
        );
      } catch (error) {
        debugPrint(
          '[AssessmentService] createSession Firestore write deferred/offline ($error), proceeding locally with session=${session.id}',
        );
      }
    }
    return session;
  }

  Future<AssessmentResult> saveResult({
    required String schoolId,
    required String classId,
    required String sessionId,
    required String studentId,
    required String teacherId,
    required Subject subject,
    required ResponseLevel level,
    required int durationSec,
    required Language language,
    ResponseLevel? autoLevel,
    double? wordsPerMinute,
    double? accuracy,
    List<String> errorWords = const [],
    int? itemsCorrect,
    int? itemsTotal,
    String? notes,
  }) async {
    final effectiveTeacherId = _resolveTeacherId(teacherId);
    final firestore = _firestore;
    final resultId = firestore != null
        ? firestore.collection(FirestorePaths.assessmentResults).doc().id
        : 'result-${DateTime.now().microsecondsSinceEpoch}';

    debugPrint(
      '[AssessmentService] saveResult start '
      'result=$resultId session=$sessionId student=$studentId '
      'subject=${subject.name}',
    );
    final result = AssessmentResult(
      id: resultId,
      schoolId: schoolId,
      classId: classId,
      sessionId: sessionId,
      studentId: studentId,
      teacherId: effectiveTeacherId,
      subject: subject,
      language: language,
      level: level,
      autoLevel: autoLevel,
      durationSec: durationSec,
      createdAt: DateTime.now(),
      wordsPerMinute: wordsPerMinute,
      accuracy: accuracy,
      errorWords: errorWords,
      itemsCorrect: itemsCorrect,
      itemsTotal: itemsTotal,
      notes: notes,
    );

    if (firestore != null) {
      final reference =
          firestore.collection(FirestorePaths.assessmentResults).doc(resultId);
      final batch = firestore.batch()..set(reference, result.toMap());
      // Sample learners do not have corresponding Firestore student documents.
      if (!studentId.startsWith('temporary-')) {
        batch.set(
          firestore.collection(FirestorePaths.students).doc(studentId),
          {
            'status': supportStatusFromLevel(level).name,
            'lastAssessedAt': Timestamp.fromDate(result.createdAt),
          },
          SetOptions(merge: true),
        );
      }
      try {
        await batch.commit().timeout(const Duration(seconds: 5));
        debugPrint(
          '[AssessmentService] saveResult success result=$resultId',
        );
      } catch (error) {
        debugPrint(
          '[AssessmentService] saveResult Firestore write deferred/offline ($error), saved locally: ${result.id}',
        );
      }
    }
    return result;
  }

  Future<void> completeSession(String sessionId) async {
    debugPrint('[AssessmentService] completeSession start session=$sessionId');
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(FirestorePaths.assessments)
          .doc(sessionId)
          .update({'status': SessionStatus.completed.name})
          .timeout(const Duration(seconds: 5));
      debugPrint(
        '[AssessmentService] completeSession success session=$sessionId',
      );
    } catch (error) {
      debugPrint(
        '[AssessmentService] completeSession Firestore update deferred/offline: $error',
      );
    }
  }

  String _resolveTeacherId(String fallback) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {
      // Firebase not initialized
    }
    return fallback;
  }
}

SupportStatus supportStatusFromLevel(ResponseLevel level) => switch (level) {
  ResponseLevel.struggling => SupportStatus.needsSupport,
  ResponseLevel.developing => SupportStatus.watch,
  ResponseLevel.proficient => SupportStatus.onTrack,
};
