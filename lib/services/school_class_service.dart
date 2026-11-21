// OWNER: Member 1. Schools list (for registration) and the teacher's classes (classes where teacherId == uid).
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/failure.dart';
import '../core/firebase_guard.dart';
import '../core/firestore_paths.dart';
import '../models/school.dart';
import '../models/school_class.dart';

class SchoolClassService {
  SchoolClassService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection(FirestorePaths.classes);

  /// READ: every school, for the registration dropdown.
  Future<List<School>> getSchools() => guardFirebase(() async {
    final snapshot = await _db
        .collection(FirestorePaths.schools)
        .orderBy('name')
        .get();
    return snapshot.docs.map(School.fromFirestore).toList();
  });

  /// READ: live list of the teacher's classes.
  Stream<List<SchoolClass>> watchMyClasses(String teacherId) => _classes
      .where('teacherId', isEqualTo: teacherId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(SchoolClass.fromFirestore).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  /// CREATE
  Future<void> createClass(SchoolClass schoolClass) =>
      guardFirebase(() => _classes.add(schoolClass.toMap()));

  /// UPDATE
  Future<void> updateClass(SchoolClass schoolClass) => guardFirebase(
    () => _classes.doc(schoolClass.id).update(schoolClass.toMap()),
  );

  /// DELETE. Refused while the class still has students so none are orphaned.
  Future<void> deleteClass(SchoolClass schoolClass) => guardFirebase(() async {
    final students = await _db
        .collection(FirestorePaths.students)
        .where('schoolId', isEqualTo: schoolClass.schoolId)
        .where('classId', isEqualTo: schoolClass.id)
        .limit(1)
        .get();
    if (students.docs.isNotEmpty) {
      throw const Failure(
        'This class still has students. Remove or move them first.',
      );
    }
    await _classes.doc(schoolClass.id).delete();
  });
}
