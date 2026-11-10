import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

class TestQuestion extends Equatable {
  const TestQuestion({required this.prompt, required this.answer});
  final String prompt; // "12 ÷ 3 = ?"
  final String answer; // "4"

  factory TestQuestion.fromMap(Map<String, dynamic> m) =>
      TestQuestion(prompt: m['prompt'] as String, answer: m['answer'] as String);

  Map<String, dynamic> toMap() => {'prompt': prompt, 'answer': answer};

  @override
  List<Object?> get props => [prompt, answer];
}

/// A test written by a teacher: a reading passage OR a list of math questions.
class AssessmentTest extends Equatable {
  const AssessmentTest({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.title,
    required this.subject,
    required this.grade,
    required this.createdAt,
    this.language = Language.english,
    this.passageText,
    this.questions = const [],
  });
  final String id; // PK
  final String schoolId; // FK -> schools
  final String createdBy; // FK -> users
  final String title;
  final Subject subject;
  final Language language;
  final int grade; // 1..3
  final DateTime createdAt;
  final String? passageText; // reading
  final List<TestQuestion> questions; // math

  /// Used by auto-grading (accuracy = correct words / wordCount).
  int get wordCount => (passageText ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;

  factory AssessmentTest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AssessmentTest(
      id: doc.id,
      schoolId: d['schoolId'] as String,
      createdBy: d['createdBy'] as String,
      title: d['title'] as String,
      subject: Subject.values.byName(d['subject'] as String),
      language: Language.values.byName(d['language'] as String),
      grade: d['grade'] as int,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      passageText: d['passageText'] as String?,
      questions: (d['questions'] as List? ?? const [])
          .map((q) => TestQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'createdBy': createdBy,
        'title': title,
        'subject': subject.name,
        'language': language.name,
        'grade': grade,
        'createdAt': Timestamp.fromDate(createdAt),
        'passageText': passageText,
        'questions': questions.map((q) => q.toMap()).toList(),
      };

  @override
  List<Object?> get props => [id, schoolId, createdBy, title, subject, language, grade, createdAt, passageText, questions];
}
