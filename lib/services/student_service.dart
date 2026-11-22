import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/failure.dart';
import '../core/firebase_guard.dart';
import '../core/firestore_paths.dart';
import '../models/assessment_result.dart';
import '../models/student.dart';

class StudentService {
  StudentService({FirebaseFirestore? db, FirebaseFirestore? firestore})
    : _db = db ?? firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection(FirestorePaths.students);

  /// Firestore rules only allow reading docs from your own school, so the
  /// query must filter on schoolId too or Firestore rejects the whole query.
  Stream<List<Student>> streamStudents(String classId, {String? schoolId}) {
    Query<Map<String, dynamic>> q = _students.where(
      'classId',
      isEqualTo: classId,
    );
    if (schoolId != null) q = q.where('schoolId', isEqualTo: schoolId);
    return q.snapshots().map(
      (snap) =>
          snap.docs.map(Student.fromFirestore).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  /// READ: live list of students in a class, ordered by roll number.
  Stream<List<Student>> watchStudents(String classId, {String? schoolId}) {
    Query<Map<String, dynamic>> q = _students.where(
      'classId',
      isEqualTo: classId,
    );
    if (schoolId != null) q = q.where('schoolId', isEqualTo: schoolId);
    return q.snapshots().map(
      (snap) =>
          snap.docs.map(Student.fromFirestore).toList()
            ..sort((a, b) => a.rollNo.compareTo(b.rollNo)),
    );
  }

  /// Every saved result for one class (used by profile + class progress).
  Stream<List<AssessmentResult>> streamClassResults(
    String classId, {
    String? schoolId,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection(FirestorePaths.assessmentResults)
        .where('classId', isEqualTo: classId);
    if (schoolId != null) q = q.where('schoolId', isEqualTo: schoolId);
    return q.snapshots().map(
      (snap) => snap.docs.map(AssessmentResult.fromFirestore).toList(),
    );
  }

  Stream<Student?> watchStudent(String id) => _students
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Student.fromFirestore(d) : null);

  Future<Student?> getStudent(String id) async {
    final d = await _students.doc(id).get();
    return d.exists ? Student.fromFirestore(d) : null;
  }

  Future<void> updateStudent(Student s) =>
      guardFirebase(() => _students.doc(s.id).update(s.toMap()));

  /// CREATE: adds a student to the Firestore `students` collection.
  Future<void> addStudent(Student student) => guardFirebase(() async {
    if (Firebase.apps.isEmpty) {
      throw const Failure('Firebase is not initialized.');
    }
    await _students.add(student.toMap());
  });

  /// DELETE
  Future<void> deleteStudent(String studentId) =>
      guardFirebase(() => _students.doc(studentId).delete());
}
