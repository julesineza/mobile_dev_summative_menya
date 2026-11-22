import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/firestore_paths.dart';
import '../models/student.dart';

class StudentService {
  StudentService({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.students);

  Stream<List<Student>> streamStudents(String classId) => _col
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(Student.fromFirestore).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

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
