import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

/// One learner's result inside a session. Graded TWO ways:
///  - [autoLevel]: computed by the app (see core/grading.dart) from word taps / answers
///  - [level]: the teacher's final 1-2-3 choice (the teacher confirms or overrides the auto level)
class AssessmentResult extends Equatable {
  const AssessmentResult({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.sessionId,
    required this.studentId,
    required this.teacherId,
    required this.subject,
    required this.level,
    required this.durationSec,
    required this.createdAt,
    this.language = Language.english,
    this.autoLevel,
    this.wordsPerMinute,
    this.accuracy,
    this.errorWords = const [],
    this.itemsCorrect,
    this.itemsTotal,
    this.notes,
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String classId; // FK -> classes (class-progress screen queries by this)
  final String sessionId; // FK -> assessments
  final String studentId; // FK -> students
  final String teacherId; // FK -> users
  final Subject subject;
  final Language language;
  final ResponseLevel level; // teacher's final decision
  final ResponseLevel? autoLevel; // automatic suggestion
  final int durationSec;
  final DateTime createdAt;
  final double? wordsPerMinute; // reading only
  final double? accuracy; // 0..100 (reading: words; math: answers)
  final List<String> errorWords; // reading: words tapped as errors
  final int? itemsCorrect; // math
  final int? itemsTotal; // math
  final String? notes;

  bool get teacherOverrode => autoLevel != null && autoLevel != level;

  factory AssessmentResult.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AssessmentResult(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      classId: d['classId'] as String,
      sessionId: d['sessionId'] as String,
      studentId: d['studentId'] as String,
      teacherId: d['teacherId'] as String,
      subject: Subject.values.byName(d['subject'] as String),
      language: Language.values.byName(d['language'] as String),
      level: ResponseLevel.fromValue(d['level'] as int),
      autoLevel: d['autoLevel'] == null ? null : ResponseLevel.fromValue(d['autoLevel'] as int),
      durationSec: d['durationSec'] as int,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      wordsPerMinute: (d['wordsPerMinute'] as num?)?.toDouble(),
      accuracy: (d['accuracy'] as num?)?.toDouble(),
      errorWords: List<String>.from(d['errorWords'] as List? ?? const []),
      itemsCorrect: d['itemsCorrect'] as int?,
      itemsTotal: d['itemsTotal'] as int?,
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classId': classId,
        'sessionId': sessionId,
        'studentId': studentId,
        'teacherId': teacherId,
        'subject': subject.name,
        'language': language.name,
        'level': level.value,
        'autoLevel': autoLevel?.value,
        'durationSec': durationSec,
        'createdAt': Timestamp.fromDate(createdAt),
        'wordsPerMinute': wordsPerMinute,
        'accuracy': accuracy,
        'errorWords': errorWords,
        'itemsCorrect': itemsCorrect,
        'itemsTotal': itemsTotal,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, schoolId, classId, sessionId, studentId, teacherId, subject, language, level, autoLevel, durationSec, createdAt, wordsPerMinute, accuracy, errorWords, itemsCorrect, itemsTotal, notes];
}
