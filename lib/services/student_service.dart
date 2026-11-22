import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/assessment_result.dart';
import '../core/firestore_paths.dart';
import '../models/student.dart';

class StudentService {
  StudentService({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.students);

  /// Firestore rules only allow reading docs from your own school, so the
  /// query must filter on schoolId too or Firestore rejects the whole query.
  Stream<List<Student>> streamStudents(String classId, {String? schoolId}) {
    Query<Map<String, dynamic>> q = _col.where('classId', isEqualTo: classId);
    if (schoolId != null) q = q.where('schoolId', isEqualTo: schoolId);
    return q.snapshots().map(
      (snap) =>
          snap.docs.map(Student.fromFirestore).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
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

  Stream<Student?> watchStudent(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Student.fromFirestore(d) : null);

  Future<Student?> getStudent(String id) async {
    final d = await _col.doc(id).get();
    return d.exists ? Student.fromFirestore(d) : null;
  }

  String addStudent(Student s) {
    final ref = _col.doc();
    ref
        .set(s.toMap())
        .catchError((Object e) => debugPrint('Add student sync failed: $e'));
    return ref.id;
  }

  Future<void> updateStudent(Student s) => _col.doc(s.id).update(s.toMap());

  Future<void> deleteStudent(String id) => _col.doc(id).delete();
}
