import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/firebase_guard.dart';
import '../core/firestore_paths.dart';
import '../models/assessment_result.dart';
import '../models/assessment_session.dart';
import '../models/assessment_test.dart';
import '../models/enums.dart';
import '../models/student.dart';

/// Single source of truth for all assessment, student, and test data via Firebase Firestore.
///
/// Writes (tests, sessions, results) never wait for the server: the document
/// is applied to Firestore's offline cache straight away and synced later, so
/// saving works on weak or no internet. A write the server rejects is
/// reported through [onSyncError] (same pattern as StudentService).
class AssessmentService {
  AssessmentService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  /// Called when a background write is rejected (e.g. permission denied).
  void Function(Failure failure)? onSyncError;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Finds a test for this school, subject and grade in Firestore.
  /// When the school has none yet, returns the built-in default test. The
  /// default only lives in memory: nothing is written to the database.
  Future<AssessmentTest> getTest({
    required String schoolId,
    required Subject subject,
    required int grade,
  }) async {
    final firestore = _firestore;
    // No Firestore available (e.g. in unit tests): use the built-in test.
    if (firestore == null) {
      return _buildDefaultTest(
        schoolId: schoolId,
        subject: subject,
        grade: grade,
      );
    }

    try {
      final snapshot = await firestore
          .collection(FirestorePaths.tests)
          .where('schoolId', isEqualTo: schoolId)
          .where('subject', isEqualTo: subject.name)
          .where('grade', isEqualTo: grade)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AssessmentTest.fromFirestore(snapshot.docs.first);
      }
      return _buildDefaultTest(
        schoolId: schoolId,
        subject: subject,
        grade: grade,
      );
    } catch (e) {
      debugPrint('[AssessmentService] getTest error from Firestore: $e');
      throw const Failure(
        'Could not load the test. Check your connection and try again.',
      );
    }
  }

  /// Saves a custom test. Returns at once; the write syncs in the background.
  Future<AssessmentTest> createTest({
    required String schoolId,
    required String title,
    required Subject subject,
    required int grade,
    Language language = Language.english,
    String? passageText,
    List<TestQuestion> questions = const [],
  }) async {
    final firestore = _firestore;
    final testDoc = firestore?.collection(FirestorePaths.tests).doc();
    final test = AssessmentTest(
      id: testDoc?.id ?? 'test-${DateTime.now().microsecondsSinceEpoch}',
      schoolId: schoolId,
      createdBy: _teacherId(firestore),
      title: title,
      subject: subject,
      grade: grade,
      createdAt: DateTime.now(),
      language: language,
      passageText: passageText,
      questions: questions,
    );

    if (testDoc != null) {
      _syncInBackground('createTest', () => testDoc.set(test.toMap()));
    }
    return test;
  }

  /// Retrieves tests from Cloud Firestore.
  Future<List<AssessmentTest>> getTests({
    required String schoolId,
    Subject? subject,
    int? grade,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return const [];

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection(FirestorePaths.tests)
          .where('schoolId', isEqualTo: schoolId);

      if (subject != null) {
        query = query.where('subject', isEqualTo: subject.name);
      }
      if (grade != null) {
        query = query.where('grade', isEqualTo: grade);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(AssessmentTest.fromFirestore).toList();
    } catch (e) {
      debugPrint('[AssessmentService] getTests error from Firestore: $e');
      return const [];
    }
  }

  /// Fetches students belonging to a class directly from Cloud Firestore.
  /// An empty class returns an empty list (the screen shows an empty state);
  /// we never write sample students into a real class.
  Future<List<Student>> getStudents({
    required String classId,
    required String schoolId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore
          .collection(FirestorePaths.students)
          .where('schoolId', isEqualTo: schoolId)
          .where('classId', isEqualTo: classId)
          .get();

      final list = snapshot.docs.map(Student.fromFirestore).toList();
      list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
      return list;
    } catch (e) {
      debugPrint('[AssessmentService] getStudents error from Firestore: $e');
      throw const Failure(
        'Could not load learners. Check your connection and try again.',
      );
    }
  }

  /// Creates a live assessment session. Returns at once; syncs in background.
  Future<AssessmentSession> createSession({
    required String schoolId,
    required String classId,
    required AssessmentTest test,
    required List<String> studentIds,
  }) async {
    final firestore = _firestore;
    final sessionDoc = firestore?.collection(FirestorePaths.assessments).doc();
    final session = AssessmentSession(
      id: sessionDoc?.id ?? 'session-${DateTime.now().microsecondsSinceEpoch}',
      schoolId: schoolId,
      classId: classId,
      teacherId: _teacherId(firestore),
      testId: test.id,
      subject: test.subject,
      language: test.language,
      studentIds: studentIds,
      createdAt: DateTime.now(),
    );

    if (sessionDoc != null) {
      _syncInBackground(
        'createSession',
        () => sessionDoc.set(session.toMap()),
      );
    }
    return session;
  }

  /// Saves one learner's result and updates the student's status and
  /// lastAssessedAt. Returns at once; the batch syncs in the background.
  Future<AssessmentResult> saveResult({
    required String schoolId,
    required String classId,
    required String sessionId,
    required String studentId,
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
    final firestore = _firestore;
    final resultDoc = firestore
        ?.collection(FirestorePaths.assessmentResults)
        .doc();

    final result = AssessmentResult(
      id: resultDoc?.id ?? 'result-${DateTime.now().microsecondsSinceEpoch}',
      schoolId: schoolId,
      classId: classId,
      sessionId: sessionId,
      studentId: studentId,
      teacherId: _teacherId(firestore),
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

    if (firestore != null && resultDoc != null) {
      final batch = firestore.batch();
      batch.set(resultDoc, result.toMap());
      batch.set(
        firestore.collection(FirestorePaths.students).doc(studentId),
        {
          'status': supportStatusFromLevel(level).name,
          'lastAssessedAt': Timestamp.fromDate(result.createdAt),
        },
        SetOptions(merge: true),
      );
      _syncInBackground('saveResult', batch.commit);
    }
    return result;
  }

  /// Marks a session as completed. Returns at once; syncs in background.
  Future<void> completeSession(String sessionId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    _syncInBackground(
      'completeSession',
      () => firestore
          .collection(FirestorePaths.assessments)
          .doc(sessionId)
          .update({'status': SessionStatus.completed.name}),
    );
  }

  /// Fetches all assessment results for a given session directly from Cloud Firestore.
  Future<List<AssessmentResult>> getResultsForSession(String sessionId) async {
    final firestore = _firestore;
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore
          .collection(FirestorePaths.assessmentResults)
          .where('sessionId', isEqualTo: sessionId)
          .get();
      return snapshot.docs.map(AssessmentResult.fromFirestore).toList();
    } catch (e) {
      debugPrint('[AssessmentService] getResultsForSession error: $e');
      return const [];
    }
  }

  /// Starts a write without waiting for the server, so the UI never hangs
  /// offline, but still reports a rejected write instead of hiding it.
  void _syncInBackground(String label, Future<void> Function() write) {
    guardFirebase(write).catchError((Object e) {
      debugPrint('[AssessmentService] $label sync failed: $e');
      onSyncError?.call(
        e is Failure
            ? e
            : const Failure('Something went wrong. Please try again.'),
      );
    });
  }

  /// The signed-in teacher's uid. Saving to Firestore requires a sign-in;
  /// without Firestore (unit tests) nothing is saved, so an empty id is fine.
  String _teacherId(FirebaseFirestore? firestore) {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      uid = null;
    }
    if (uid != null && uid.isNotEmpty) return uid;
    if (firestore == null) return '';
    throw const Failure('Please sign in again to save assessments.');
  }

  /// Built-in test used when a school has none yet (kept in memory only).
  AssessmentTest _buildDefaultTest({
    required String schoolId,
    required Subject subject,
    required int grade,
  }) {
    if (subject == Subject.math) {
      return AssessmentTest(
        id: '$schoolId-math-grade-$grade-default',
        schoolId: schoolId,
        createdBy: 'teacher-system',
        title: 'P$grade · Math Quick Check',
        subject: Subject.math,
        grade: grade,
        createdAt: DateTime.now(),
        questions: const [
          TestQuestion(prompt: '12 ÷ 3 = ?', answer: '4'),
          TestQuestion(prompt: '6 + 7 = ?', answer: '13'),
          TestQuestion(prompt: '5 × 2 = ?', answer: '10'),
          TestQuestion(prompt: '18 - 9 = ?', answer: '9'),
        ],
      );
    }

    return AssessmentTest(
      id: '$schoolId-reading-grade-$grade-default',
      schoolId: schoolId,
      createdBy: 'teacher-system',
      title: 'P$grade · English Reading Check',
      subject: Subject.reading,
      grade: grade,
      createdAt: DateTime.now(),
      passageText:
          'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.',
    );
  }
}

SupportStatus supportStatusFromLevel(ResponseLevel level) => switch (level) {
  ResponseLevel.struggling => SupportStatus.needsSupport,
  ResponseLevel.developing => SupportStatus.watch,
  ResponseLevel.proficient => SupportStatus.onTrack,
};
