import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

/// One "quick check": a teacher runs ONE test over one or more learners of ONE class.
class AssessmentSession extends Equatable {
  const AssessmentSession({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.teacherId,
    required this.testId,
    required this.subject,
    required this.studentIds,
    required this.createdAt,
    this.language = Language.english,
    this.status = SessionStatus.inProgress,
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String classId; // FK -> classes
  final String teacherId; // FK -> users
  final String testId; // FK -> tests (which passage/questions were used)
  final Subject subject;
  final Language language;
  final List<String> studentIds; // FKs -> students
  final DateTime createdAt;
  final SessionStatus status;

  factory AssessmentSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AssessmentSession(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      classId: d['classId'] as String,
      teacherId: d['teacherId'] as String,
      testId: d['testId'] as String,
      subject: Subject.values.byName(d['subject'] as String),
      language: Language.values.byName(d['language'] as String),
      studentIds: List<String>.from(d['studentIds'] as List),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      status: SessionStatus.values.byName(d['status'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classId': classId,
        'teacherId': teacherId,
        'testId': testId,
        'subject': subject.name,
        'language': language.name,
        'studentIds': studentIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, schoolId, classId, teacherId, testId, subject, language, studentIds, createdAt, status];
}
