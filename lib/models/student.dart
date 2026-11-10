import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

class Student extends Equatable {
  const Student({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.name,
    required this.rollNo,
    this.status = SupportStatus.onTrack,
    this.lastAssessedAt,
  });
  final String id; // PK
  final String schoolId; // FK -> schools (kept for easy security rules)
  final String classId; // FK -> classes (a student belongs to exactly one class)
  final String name;
  final int rollNo;
  final SupportStatus status; // updated after each graded result
  final DateTime? lastAssessedAt;

  factory Student.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Student(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      classId: d['classId'] as String,
      name: d['name'] as String,
      rollNo: d['rollNo'] as int,
      status: SupportStatus.values.byName(d['status'] as String),
      lastAssessedAt: (d['lastAssessedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classId': classId,
        'name': name,
        'rollNo': rollNo,
        'status': status.name,
        'lastAssessedAt':
            lastAssessedAt == null ? null : Timestamp.fromDate(lastAssessedAt!),
      };

  @override
  List<Object?> get props => [id, schoolId, classId, name, rollNo, status, lastAssessedAt];
}
