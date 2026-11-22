import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/failure.dart';
import '../core/firebase_guard.dart';
import '../core/firestore_paths.dart';
import '../models/student.dart';

class StudentService {
  StudentService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection(FirestorePaths.students);

  /// READ: live list of students in a class, ordered by roll number.
  Stream<List<Student>> watchStudents(String classId) => _students
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(Student.fromFirestore).toList()
              ..sort((a, b) => a.rollNo.compareTo(b.rollNo)),
      );

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
