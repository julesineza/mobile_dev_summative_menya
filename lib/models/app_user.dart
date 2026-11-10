import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A teacher. Their classes are found with: classes where teacherId == uid.
class AppUser extends Equatable {
  const AppUser({required this.uid, required this.name, required this.email, required this.schoolId});
  final String uid; // PK = Firebase Auth uid
  final String name;
  final String email;
  final String schoolId; // FK -> schools

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      uid: doc.id,
      name: d['name'] as String,
      email: d['email'] as String,
      schoolId: d['schoolId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'email': email, 'schoolId': schoolId};

  @override
  List<Object?> get props => [uid, name, email, schoolId];
}
