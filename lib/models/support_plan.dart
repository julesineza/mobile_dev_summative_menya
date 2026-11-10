import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

class SupportPlan extends Equatable {
  const SupportPlan({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.studentId,
    required this.resultId,
    required this.teacherId,
    required this.focus,
    required this.practiceType,
    required this.createdAt,
    this.recheckDate,
    this.status = PlanStatus.active,
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String classId; // FK -> classes
  final String studentId; // FK -> students
  final String resultId; // FK -> assessmentResults (what triggered the plan)
  final String teacherId; // FK -> users
  final String focus; // e.g. "letter sounds"
  final String practiceType; // e.g. "word practice"
  final DateTime createdAt;
  final DateTime? recheckDate;
  final PlanStatus status;

  factory SupportPlan.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SupportPlan(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      classId: d['classId'] as String,
      studentId: d['studentId'] as String,
      resultId: d['resultId'] as String,
      teacherId: d['teacherId'] as String,
      focus: d['focus'] as String,
      practiceType: d['practiceType'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      recheckDate: (d['recheckDate'] as Timestamp?)?.toDate(),
      status: PlanStatus.values.byName(d['status'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classId': classId,
        'studentId': studentId,
        'resultId': resultId,
        'teacherId': teacherId,
        'focus': focus,
        'practiceType': practiceType,
        'createdAt': Timestamp.fromDate(createdAt),
        'recheckDate': recheckDate == null ? null : Timestamp.fromDate(recheckDate!),
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, schoolId, classId, studentId, resultId, teacherId, focus, practiceType, createdAt, recheckDate, status];
}
