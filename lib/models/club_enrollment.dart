import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

/// "Student X is in club Y." One document per student per club.
/// Club roster:   clubEnrollments where clubId == Y and status == active
/// Student clubs: clubEnrollments where studentId == X
class ClubEnrollment extends Equatable {
  const ClubEnrollment({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.clubId,
    required this.studentId,
    required this.enrolledBy,
    required this.enrolledAt,
    this.resultId,
    this.status = EnrollmentStatus.active,
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String classId; // FK -> classes
  final String clubId; // FK -> remedialClubs
  final String studentId; // FK -> students
  final String enrolledBy; // FK -> users
  final DateTime enrolledAt;
  final String? resultId; // FK -> assessmentResults (the poor result that triggered it)
  final EnrollmentStatus status;

  factory ClubEnrollment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ClubEnrollment(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      classId: d['classId'] as String,
      clubId: d['clubId'] as String,
      studentId: d['studentId'] as String,
      enrolledBy: d['enrolledBy'] as String,
      enrolledAt: (d['enrolledAt'] as Timestamp).toDate(),
      resultId: d['resultId'] as String?,
      status: EnrollmentStatus.values.byName(d['status'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classId': classId,
        'clubId': clubId,
        'studentId': studentId,
        'enrolledBy': enrolledBy,
        'enrolledAt': Timestamp.fromDate(enrolledAt),
        'resultId': resultId,
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, schoolId, classId, clubId, studentId, enrolledBy, enrolledAt, resultId, status];
}
