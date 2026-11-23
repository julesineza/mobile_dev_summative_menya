// owner: member 4. support plans, rechecks and learner history.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/failure.dart';
import '../core/firestore_paths.dart';
import '../core/grading.dart';
import '../models/assessment_result.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../models/support_plan.dart';

/// list queries filter on schoolId, as the rules only allow reading your own school.
/// lists are sorted here instead of with orderBy, so no composite indexes are needed.
class SupportPlanService {
  SupportPlanService({FirebaseFirestore? db}) : _dbOverride = db;

  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection(FirestorePaths.supportPlans);
  CollectionReference<Map<String, dynamic>> get _results =>
      _db.collection(FirestorePaths.assessmentResults);

  Future<T> _guard<T>(Future<T> Function() action, String message) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw Failure(
        e.code == 'permission-denied'
            ? 'You do not have permission to do that.'
            : message,
      );
    }
  }

  Future<AssessmentResult?> getResult(String resultId) => _guard(() async {
    final doc = await _results.doc(resultId).get();
    return doc.exists ? AssessmentResult.fromFirestore(doc) : null;
  }, 'Could not load this result.');

  Future<Student?> getStudent(String studentId) => _guard(() async {
    final doc = await _db
        .collection(FirestorePaths.students)
        .doc(studentId)
        .get();
    return doc.exists ? Student.fromFirestore(doc) : null;
  }, 'Could not load this learner.');

  /// newest first.
  Future<List<AssessmentResult>> getResultsForStudent(
    String studentId, {
    required String schoolId,
  }) => _guard(() async {
    final snap = await _results
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.map(AssessmentResult.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }, 'Could not load saved checks.');

  /// newest first.
  Future<List<SupportPlan>> getPlansForStudent(
    String studentId, {
    required String schoolId,
  }) => _guard(() async {
    final snap = await _plans
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.map(SupportPlan.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }, 'Could not load support plans.');

  Future<SupportPlan> createPlan({
    required String schoolId,
    required String classId,
    required String studentId,
    required String resultId,
    required String teacherId,
    required String focus,
    required String practiceType,
    DateTime? recheckDate,
  }) => _guard(() async {
    final ref = _plans.doc();
    final plan = SupportPlan(
      id: ref.id,
      schoolId: schoolId,
      classId: classId,
      studentId: studentId,
      resultId: resultId,
      teacherId: teacherId,
      focus: focus,
      practiceType: practiceType,
      createdAt: DateTime.now(),
      recheckDate: recheckDate,
    );
    await ref.set(plan.toMap());
    return plan;
  }, 'Could not save the support plan.');

  /// saves the final level and note, and updates the learner status to match.
  Future<void> updateResultReview({
    required String resultId,
    required String studentId,
    required ResponseLevel level,
    String? notes,
  }) => _guard(() async {
    final batch = _db.batch();
    batch.update(_results.doc(resultId), {
      'level': level.value,
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    });
    batch.update(_db.collection(FirestorePaths.students).doc(studentId), {
      'status': Grading.statusFromLevel(level).name,
    });
    await batch.commit();
  }, 'Could not save the review.');

  Future<void> scheduleRecheck(String planId, DateTime recheckDate) => _guard(
    () => _plans.doc(planId).update({
      'recheckDate': Timestamp.fromDate(recheckDate),
    }),
    'Could not set the recheck date.',
  );

  Future<void> setPlanStatus(String planId, PlanStatus status) => _guard(
    () => _plans.doc(planId).update({'status': status.name}),
    'Could not update the plan.',
  );

  Future<void> deletePlan(String planId) =>
      _guard(() => _plans.doc(planId).delete(), 'Could not delete the plan.');
}
