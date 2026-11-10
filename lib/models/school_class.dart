import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A class such as "P3-A". `class` is a Dart keyword, hence SchoolClass.
class SchoolClass extends Equatable {
  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.teacherId,
    required this.name,
    required this.grade,
    this.academicYear,
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String teacherId; // FK -> users (one teacher can have many classes)
  final String name; // "P3-A"
  final int grade; // 1..6
  final String? academicYear; // "2026"

  factory SchoolClass.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SchoolClass(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      teacherId: d['teacherId'] as String,
      name: d['name'] as String,
      grade: d['grade'] as int,
      academicYear: d['academicYear'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'teacherId': teacherId,
        'name': name,
        'grade': grade,
        'academicYear': academicYear,
      };

  @override
  List<Object?> get props => [id, schoolId, teacherId, name, grade, academicYear];
}
