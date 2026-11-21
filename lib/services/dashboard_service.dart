// OWNER: Member 1. Read-only queries that feed the home dashboard.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/assessment_session.dart';
import '../models/school_class.dart';
import '../models/student.dart';

class DashboardService {
  DashboardService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Every student in the class (the dashboard counts them by status).
  Stream<List<Student>> watchStudents(SchoolClass schoolClass) => _db
      .collection(FirestorePaths.students)
      .where('schoolId', isEqualTo: schoolClass.schoolId)
      .where('classId', isEqualTo: schoolClass.id)
      .snapshots()
      .map((s) => s.docs.map(Student.fromFirestore).toList());

  /// Latest quick checks (sessions) for the class, newest first.
  /// Needs the composite index in firestore.indexes.json.
  Stream<List<AssessmentSession>> watchRecentSessions(
    SchoolClass schoolClass, {
    int limit = 5,
  }) => _db
      .collection(FirestorePaths.assessments)
      .where('schoolId', isEqualTo: schoolClass.schoolId)
      .where('classId', isEqualTo: schoolClass.id)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AssessmentSession.fromFirestore).toList());
}
