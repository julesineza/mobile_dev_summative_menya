// owner: member 4. remedial clubs and enrollments.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/failure.dart';
import '../core/firestore_paths.dart';
import '../models/club_enrollment.dart';
import '../models/enums.dart';
import '../models/remedial_club.dart';

class ClubService {
  ClubService({FirebaseFirestore? db}) : _dbOverride = db;

  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _clubs =>
      _db.collection(FirestorePaths.remedialClubs);
  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _db.collection(FirestorePaths.clubEnrollments);

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

  Future<RemedialClub> createClub({
    required String schoolId,
    required String createdBy,
    required String name,
    required Subject subject,
    String? schedule,
  }) => _guard(() async {
    final ref = _clubs.doc();
    final club = RemedialClub(
      id: ref.id,
      schoolId: schoolId,
      createdBy: createdBy,
      name: name.trim(),
      subject: subject,
      schedule: (schedule == null || schedule.trim().isEmpty)
          ? null
          : schedule.trim(),
    );
    await ref.set(club.toMap());
    return club;
  }, 'Could not create the club.');

  Future<List<RemedialClub>> getClubs(String schoolId) => _guard(() async {
    final snap = await _clubs.where('schoolId', isEqualTo: schoolId).get();
    return snap.docs.map(RemedialClub.fromFirestore).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }, 'Could not load clubs.');

  /// re-enrolling reactivates the existing enrollment instead of duplicating it.
  Future<ClubEnrollment> enrollStudent({
    required String schoolId,
    required String classId,
    required String clubId,
    required String studentId,
    required String enrolledBy,
    String? resultId,
  }) => _guard(() async {
    final existing = await _enrollments
        .where('schoolId', isEqualTo: schoolId)
        .where('clubId', isEqualTo: clubId)
        .where('studentId', isEqualTo: studentId)
        .get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await doc.reference.update({'status': EnrollmentStatus.active.name});
      return ClubEnrollment.fromFirestore(await doc.reference.get());
    }
    final ref = _enrollments.doc();
    final enrollment = ClubEnrollment(
      id: ref.id,
      schoolId: schoolId,
      classId: classId,
      clubId: clubId,
      studentId: studentId,
      enrolledBy: enrolledBy,
      enrolledAt: DateTime.now(),
      resultId: resultId,
    );
    await ref.set(enrollment.toMap());
    return enrollment;
  }, 'Could not add the learner to the club.');

  Future<void> exitStudent(String enrollmentId) => _guard(
    () => _enrollments.doc(enrollmentId).update({
      'status': EnrollmentStatus.exited.name,
    }),
    'Could not remove the learner from the club.',
  );

  Future<List<ClubEnrollment>> getMembers(
    String clubId, {
    required String schoolId,
  }) => _guard(() async {
    final snap = await _enrollments
        .where('schoolId', isEqualTo: schoolId)
        .where('clubId', isEqualTo: clubId)
        .where('status', isEqualTo: EnrollmentStatus.active.name)
        .get();
    return snap.docs.map(ClubEnrollment.fromFirestore).toList();
  }, 'Could not load club members.');

  Future<List<ClubEnrollment>> getClubsForStudent(
    String studentId, {
    required String schoolId,
  }) => _guard(() async {
    final snap = await _enrollments
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.map(ClubEnrollment.fromFirestore).toList();
  }, 'Could not load the learner\'s clubs.');
}
