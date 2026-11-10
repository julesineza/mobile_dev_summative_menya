import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class School extends Equatable {
  const School({required this.id, required this.name, this.district});
  final String id; // PK
  final String name;
  final String? district;

  factory School.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return School(id: doc.id, name: d['name'] as String, district: d['district'] as String?);
  }

  Map<String, dynamic> toMap() => {'name': name, 'district': district};

  @override
  List<Object?> get props => [id, name, district];
}
