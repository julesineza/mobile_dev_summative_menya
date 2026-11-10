import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

/// A remedial club, created by a teacher. Who is IN the club is stored in clubEnrollments.
class RemedialClub extends Equatable {
  const RemedialClub({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.name,
    required this.subject,
    this.schedule,
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String createdBy; // FK -> users (teacher who created it)
  final String name; // "Reading Club"
  final Subject subject;
  final String? schedule; // "Tue/Thu 3pm"

  factory RemedialClub.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RemedialClub(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      createdBy: d['createdBy'] as String,
      name: d['name'] as String,
      subject: Subject.values.byName(d['subject'] as String),
      schedule: d['schedule'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'createdBy': createdBy,
        'name': name,
        'subject': subject.name,
        'schedule': schedule,
      };

  @override
  List<Object?> get props => [id, schoolId, createdBy, name, subject, schedule];
}
