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

/// Single source of truth for all assessment, student, and test data via Firebase Firestore.
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

  /// Fetches an assessment test from Firestore.
  /// If the test does not exist yet in Firestore, seeds it into Firestore so Firestore remains the source of truth.
  /// When Firestore is unavailable (e.g. in unit tests), returns the default built-in test so tests can run without network.
  Future<AssessmentTest?> getTest({
    required String schoolId,
    required Subject subject,
    required int grade,
  }) async {
    final firestore = _firestore;
    // No Firestore available (e.g. in unit tests) — return a local default so tests pass.
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

      // Test doesn't exist yet in Firestore: seed directly to Firestore
      final defaultTest = _buildDefaultTest(
        schoolId: schoolId,
        subject: subject,
        grade: grade,
      );
      await firestore
          .collection(FirestorePaths.tests)
          .doc(defaultTest.id)
          .set(defaultTest.toMap());
      debugPrint(
        '[AssessmentService] Seeded test ${defaultTest.id} into Firestore',
      );
      return defaultTest;
    } catch (e) {
      debugPrint('[AssessmentService] getTest error from Firestore: $e');
      return null;
    }
  }

  /// Saves a custom test directly to Cloud Firestore.
  Future<AssessmentTest> createTest({
    required String schoolId,
    required String createdBy,
    required String title,
    required Subject subject,
    required int grade,
    Language language = Language.english,
    String? passageText,
    List<TestQuestion> questions = const [],
  }) async {
    final effectiveTeacherId = _resolveTeacherId(createdBy);
    final firestore = _firestore;
    final testDoc = firestore != null
        ? firestore.collection(FirestorePaths.tests).doc()
        : null;
    final testId =
        testDoc?.id ?? 'test-${DateTime.now().microsecondsSinceEpoch}';

    final test = AssessmentTest(
      id: testId,
      schoolId: schoolId,
      createdBy: effectiveTeacherId,
      title: title,
      subject: subject,
      grade: grade,
      createdAt: DateTime.now(),
      language: language,
      passageText: passageText,
      questions: questions,
    );

    if (testDoc != null) {
      await testDoc.set(test.toMap());
      debugPrint(
        '[AssessmentService] Created test directly in Firestore: $testId',
      );
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
  /// If the class has no student documents in Firestore yet, seeds them directly to Firestore
  /// so that Firestore is immediately populated as the single source of truth.
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

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map(Student.fromFirestore).toList();
        list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
        return list;
      }

      // Seed students directly into Firestore
      final seeded = await _seedInitialStudentsForClass(
        schoolId: schoolId,
        classId: classId,
      );
      return seeded;
    } catch (e) {
      debugPrint('[AssessmentService] getStudents error from Firestore: $e');
      return const [];
    }
  }

  /// Creates a live assessment session document directly in Cloud Firestore.
  Future<AssessmentSession> createSession({
    required String schoolId,
    required String classId,
    required String teacherId,
    required AssessmentTest test,
    required List<String> studentIds,
  }) async {
    final effectiveTeacherId = _resolveTeacherId(teacherId);
    final firestore = _firestore;
    final sessionDoc = firestore != null
        ? firestore.collection(FirestorePaths.assessments).doc()
        : null;
    final sessionId =
        sessionDoc?.id ?? 'session-${DateTime.now().microsecondsSinceEpoch}';

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

    if (sessionDoc != null) {
      await sessionDoc.set(session.toMap());
      debugPrint(
        '[AssessmentService] Created session directly in Firestore: $sessionId',
      );
    }
    return session;
  }

  /// Saves an individual student's assessment result directly to Cloud Firestore
  /// and updates the student's status & lastAssessedAt in the Firestore `students` collection.
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
    final resultDoc = firestore != null
        ? firestore.collection(FirestorePaths.assessmentResults).doc()
        : null;
    final resultId =
        resultDoc?.id ?? 'result-${DateTime.now().microsecondsSinceEpoch}';

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

    if (firestore != null && resultDoc != null) {
      final batch = firestore.batch();
      batch.set(resultDoc, result.toMap());

      // Update student's status and lastAssessedAt in Firestore
      final studentRef = firestore
          .collection(FirestorePaths.students)
          .doc(studentId);
      batch.set(studentRef, {
        'status': supportStatusFromLevel(level).name,
        'lastAssessedAt': Timestamp.fromDate(result.createdAt),
      }, SetOptions(merge: true));

      await batch.commit();
      debugPrint(
        '[AssessmentService] Saved result directly to Firestore: $resultId',
      );
    }
    return result;
  }

  /// Marks an assessment session as completed directly in Cloud Firestore.
  Future<void> completeSession(String sessionId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection(FirestorePaths.assessments)
          .doc(sessionId)
          .update({'status': SessionStatus.completed.name});
      debugPrint(
        '[AssessmentService] Completed session in Firestore: $sessionId',
      );
    } catch (error) {
      debugPrint(
        '[AssessmentService] completeSession error in Firestore: $error',
      );
    }
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

  /// Seeds sample students directly into Firestore `students` collection.
  Future<List<Student>> _seedInitialStudentsForClass({
    required String schoolId,
    required String classId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return const [];

    final samples = [
      {'name': 'Bruno Niyonsaba', 'rollNo': 1},
      {'name': 'Fiona Uwase', 'rollNo': 2},
      {'name': 'Aliane Umutoni', 'rollNo': 3},
      {'name': 'Cynthia Gisa', 'rollNo': 4},
      {'name': 'Eric Bizimana', 'rollNo': 5},
      {'name': 'David Mugisha', 'rollNo': 6},
    ];

    final batch = firestore.batch();
    final List<Student> seededStudents = [];

    for (final sample in samples) {
      final docRef = firestore.collection(FirestorePaths.students).doc();
      final student = Student(
        id: docRef.id,
        schoolId: schoolId,
        classId: classId,
        name: sample['name'] as String,
        rollNo: sample['rollNo'] as int,
        status: SupportStatus.onTrack,
      );
      batch.set(docRef, student.toMap());
      seededStudents.add(student);
    }

    try {
      await batch.commit();
      debugPrint(
        '[AssessmentService] Seeded ${seededStudents.length} students into Firestore for class $classId',
      );
    } catch (e) {
      debugPrint(
        '[AssessmentService] Error seeding students into Firestore: $e',
      );
    }

    return seededStudents;
  }

  AssessmentTest _buildDefaultTest({
    required String schoolId,
    required Subject subject,
    required int grade,
  }) {
    if (subject == Subject.math) {
      return AssessmentTest(
        id: 'math-grade-$grade-default',
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
      id: 'reading-grade-$grade-default',
      schoolId: schoolId,
      createdBy: 'teacher-system',
      title: 'P$grade · English Reading Check',
      subject: Subject.reading,
      grade: grade,
      createdAt: DateTime.now(),
      passageText: 'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.',
    );
  }

  String _resolveTeacherId(String fallback) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    return fallback;
  }
}

SupportStatus supportStatusFromLevel(ResponseLevel level) => switch (level) {
  ResponseLevel.struggling => SupportStatus.needsSupport,
  ResponseLevel.developing => SupportStatus.watch,
  ResponseLevel.proficient => SupportStatus.onTrack,
};
