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
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<AssessmentTest?> getTest({
    required String schoolId,
    required Subject subject,
    required int grade,
  }) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.tests)
        .where('schoolId', isEqualTo: schoolId)
        .where('subject', isEqualTo: subject.name)
        .where('grade', isEqualTo: grade)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AssessmentTest.fromFirestore(snapshot.docs.first);
  }

  Future<List<Student>> getStudents({required String classId}) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.students)
        .where('classId', isEqualTo: classId)
        .orderBy('rollNo')
        .get();
    return snapshot.docs.map(Student.fromFirestore).toList();
  }

  Future<AssessmentSession> createSession({
    required String schoolId,
    required String classId,
    required String teacherId,
    required AssessmentTest test,
    required List<String> studentIds,
  }) async {
    _requireAuthenticatedUser();
    final reference = _firestore.collection(FirestorePaths.assessments).doc();
    debugPrint(
      '[AssessmentService] createSession start '
      'session=${reference.id} students=${studentIds.length}',
    );
    final session = AssessmentSession(
      id: reference.id,
      schoolId: schoolId,
      classId: classId,
      teacherId: teacherId,
      testId: test.id,
      subject: test.subject,
      language: test.language,
      studentIds: studentIds,
      createdAt: DateTime.now(),
    );
    try {
      await reference
          .set(session.toMap())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Starting the assessment took too long. Check your internet connection.',
            ),
          );
      debugPrint(
        '[AssessmentService] createSession success session=${reference.id}',
      );
    } catch (error, stackTrace) {
      _logFirestoreError('createSession', error, stackTrace);
      rethrow;
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
    _requireAuthenticatedUser();
    final reference = _firestore
        .collection(FirestorePaths.assessmentResults)
        .doc();
    debugPrint(
      '[AssessmentService] saveResult start '
      'result=${reference.id} session=$sessionId student=$studentId '
      'subject=${subject.name} uid=${FirebaseAuth.instance.currentUser?.uid}',
    );
    final result = AssessmentResult(
      id: reference.id,
      schoolId: schoolId,
      classId: classId,
      sessionId: sessionId,
      studentId: studentId,
      teacherId: teacherId,
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

    final batch = _firestore.batch()..set(reference, result.toMap());
    // Sample learners do not have corresponding Firestore student documents.
    // Do not make saving their result depend on updating a document that does
    // not exist or is not writable by the current user.
    if (!studentId.startsWith('temporary-')) {
      batch.set(_firestore.collection(FirestorePaths.students).doc(studentId), {
        'status': supportStatusFromLevel(level).name,
        'lastAssessedAt': Timestamp.fromDate(result.createdAt),
      }, SetOptions(merge: true));
    }
    try {
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Saving the assessment took too long. Check your internet connection.',
        ),
      );
      debugPrint(
        '[AssessmentService] saveResult success result=${reference.id}',
      );
    } catch (error, stackTrace) {
      _logFirestoreError('saveResult batch.commit', error, stackTrace);
      rethrow;
    }
    return result;
  }

  Future<void> completeSession(String sessionId) async {
    _requireAuthenticatedUser();
    debugPrint('[AssessmentService] completeSession start session=$sessionId');
    try {
      await _firestore
          .collection(FirestorePaths.assessments)
          .doc(sessionId)
          .update({'status': SessionStatus.completed.name})
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Finishing the assessment took too long. Check your internet connection.',
            ),
          );
      debugPrint(
        '[AssessmentService] completeSession success session=$sessionId',
      );
    } catch (error, stackTrace) {
      _logFirestoreError('completeSession', error, stackTrace);
      rethrow;
    }
  }

  void _requireAuthenticatedUser() {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError(
        'No Firebase user is signed in. Restart the app and try again.',
      );
    }
  }

  void _logFirestoreError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is FirebaseException) {
      debugPrint(
        '[AssessmentService] $operation failed '
        'code=${error.code} message=${error.message}',
      );
    } else {
      debugPrint('[AssessmentService] $operation failed: $error');
    }
    debugPrintStack(stackTrace: stackTrace);
  }
}

SupportStatus supportStatusFromLevel(ResponseLevel level) => switch (level) {
  ResponseLevel.struggling => SupportStatus.needsSupport,
  ResponseLevel.developing => SupportStatus.watch,
  ResponseLevel.proficient => SupportStatus.onTrack,
};
