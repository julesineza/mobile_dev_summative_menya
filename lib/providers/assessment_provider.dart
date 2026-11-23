import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/grading.dart';
import '../models/assessment_result.dart';
import '../models/assessment_session.dart';
import '../models/assessment_test.dart';
import '../models/enums.dart';
import '../services/assessment_service.dart';

enum UserChoice { none, reading, math }

class AssessmentLearner {
  const AssessmentLearner({
    required this.id,
    required this.name,
    required this.initials,
    required this.className,
    required this.schoolId,
    required this.classId,
  });

  final String id;
  final String name;
  final String initials;
  final String className;
  final String schoolId;
  final String classId;
}

class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider({AssessmentService? service})
    : _service = service ?? AssessmentService() {
    _service.onSyncError = _onSyncError;
  }

  final AssessmentService _service;
  UserChoice _selectedAssessment = UserChoice.none;

  // The active class always comes from ClassProvider (the teacher's real
  // classes). There are no hardcoded fallbacks: with no class, [hasClass] is
  // false and the screens ask the teacher to create one.
  String _selectedClassName = '';
  String? _selectedClassId;
  String _selectedSchoolId = '';

  /// Message of the last background write Firestore rejected, if any.
  String? _syncError;

  /// Real grade of the selected class (from the class document). Null when
  /// only the class name is known; then the grade is guessed from the name.
  int? _selectedGrade;
  AssessmentTest? _test;
  AssessmentSession? _session;
  List<AssessmentLearner> _learners = const [];
  int _currentLearnerIndex = 0;
  List<String> _errorWords = [];
  int _readingDurationSec = 0;
  double? _readingAccuracy;
  double? _readingWordsPerMinute;
  List<String> _mathAnswers = const [];
  List<AssessmentResult> _completedResults = [];

  UserChoice get selectedChoice => _selectedAssessment;
  String get selectedClassName => _selectedClassName;
  String? get selectedClassId => _selectedClassId;
  String get selectedSchoolId => _selectedSchoolId;
  bool get hasClass => _selectedClassId != null;
  String? get syncError => _syncError;
  int get selectedGrade => _selectedGrade ?? parseGrade(_selectedClassName);
  AssessmentTest? get test => _test;

  /// "English" / "Kinyarwanda" / "French" for the current test's language.
  String get testLanguageLabel => switch (_test?.language ?? Language.english) {
    Language.english => 'English',
    Language.kinyarwanda => 'Kinyarwanda',
    Language.french => 'French',
  };
  AssessmentSession? get session => _session;
  List<AssessmentLearner> get learners => _learners;
  int get currentLearnerIndex => _currentLearnerIndex;
  int get totalLearners => _learners.length;
  AssessmentLearner? get currentLearner =>
      _learners.isEmpty ? null : _learners[_currentLearnerIndex];
  bool get hasNextLearner => _currentLearnerIndex < _learners.length - 1;
  List<String> get errorWords => List.unmodifiable(_errorWords);
  int get readingDurationSec => _readingDurationSec;
  double? get readingAccuracy => _readingAccuracy;
  double? get readingWordsPerMinute => _readingWordsPerMinute;
  List<String> get mathAnswers => _mathAnswers;
  List<AssessmentResult> get completedResults =>
      List.unmodifiable(_completedResults);

  /// Called when the teacher has no class (or signed out): forget the class
  /// and any assessment in progress for it.
  void clearClass() {
    if (_selectedClassId == null) return;
    _selectedClassId = null;
    _selectedClassName = '';
    _selectedSchoolId = '';
    _selectedGrade = null;
    _test = null;
    _learners = const [];
    _currentLearnerIndex = 0;
    _session = null;
    notifyListeners();
  }

  void clearSyncError() {
    if (_syncError == null) return;
    _syncError = null;
    notifyListeners();
  }

  /// Background writes report rejections here (the UI does not wait for them).
  void _onSyncError(Failure failure) {
    _syncError = failure.message;
    notifyListeners();
  }

  /// Syncs the selected class from the real Firestore class document
  /// ([ClassProvider.selectedClass]).
  void syncFromClass({
    required String id,
    required String name,
    String? schoolId,
    int? grade,
  }) {
    final schoolChanged =
        schoolId != null &&
        schoolId.isNotEmpty &&
        schoolId != _selectedSchoolId;
    final gradeChanged = grade != null && grade != _selectedGrade;
    if (_selectedClassId == id &&
        _selectedClassName == name &&
        !schoolChanged &&
        !gradeChanged) {
      return;
    }
    _applyClass(id: id, name: name, schoolId: schoolId, grade: grade);
    notifyListeners();
  }

  /// Picks the subject. A test already chosen for the same subject (e.g. a
  /// custom test just saved on the setup screen) is kept; otherwise the
  /// default test is loaded again by [prepareAssessment].
  void setSelectedAssessment(UserChoice assessment) {
    _selectedAssessment = assessment;
    if (_test != null && _test!.subject != _subjectFor(assessment)) {
      _test = null;
    }
    _session = null;
    _currentLearnerIndex = 0;
    _completedResults = [];
    _resetLearnerState();
    notifyListeners();
  }

  /// Loads the default test for the selected subject and class grade, unless
  /// a matching test is already selected.
  /// Throws a [Failure] (from the service) when the test cannot be loaded.
  Future<void> prepareAssessment() async {
    final subject = _subjectFor(_selectedAssessment);
    if (_test != null && _test!.subject == subject) {
      notifyListeners();
      return;
    }
    _requireClass();
    _test = await _service.getTest(
      schoolId: _selectedSchoolId,
      subject: subject,
      grade: selectedGrade,
    );
    notifyListeners();
  }

  static Subject _subjectFor(UserChoice choice) =>
      choice == UserChoice.math ? Subject.math : Subject.reading;

  String _requireClass() {
    final id = _selectedClassId;
    if (id == null) {
      throw const Failure('Create or choose a class first.');
    }
    return id;
  }

  Future<AssessmentTest> _requireTest() async {
    if (_test == null) await prepareAssessment();
    final test = _test;
    if (test == null) {
      throw const Failure(
        'Could not load the test. Check your connection and try again.',
      );
    }
    return test;
  }

  Future<AssessmentTest> saveCustomTest({
    required String title,
    required Subject subject,
    required int grade,
    Language language = Language.english,
    String? passageText,
    List<TestQuestion> questions = const [],
    String? schoolId,
  }) async {
    final test = await _service.createTest(
      schoolId: schoolId ?? _selectedSchoolId,
      title: title,
      subject: subject,
      grade: grade,
      language: language,
      passageText: passageText,
      questions: questions,
    );
    _test = test;
    if (subject == Subject.reading) {
      _selectedAssessment = UserChoice.reading;
    } else if (subject == Subject.math) {
      _selectedAssessment = UserChoice.math;
    }
    notifyListeners();
    return test;
  }

  void setCustomTest(AssessmentTest test) {
    _test = test;
    if (test.subject == Subject.reading) {
      _selectedAssessment = UserChoice.reading;
    } else if (test.subject == Subject.math) {
      _selectedAssessment = UserChoice.math;
    }
    notifyListeners();
  }

  void setSelectedClass({
    required String name,
    required String id,
    String? schoolId,
    int? grade,
  }) {
    _applyClass(id: id, name: name, schoolId: schoolId, grade: grade);
    notifyListeners();
  }

  void _applyClass({
    required String id,
    required String name,
    String? schoolId,
    int? grade,
  }) {
    _selectedClassName = name;
    _selectedClassId = id;
    _selectedGrade = grade;
    if (schoolId != null && schoolId.isNotEmpty) {
      _selectedSchoolId = schoolId;
    }
    // A test written for another grade does not fit the new class.
    if (_test != null && _test!.grade != selectedGrade) {
      _test = null;
    }
    _learners = const [];
    _currentLearnerIndex = 0;
    _session = null;
  }

  void setLearners(List<AssessmentLearner> learners) {
    _learners = List.unmodifiable(learners);
    _currentLearnerIndex = 0;
    _session = null;
    _completedResults = [];
    notifyListeners();
  }

  /// Loads students directly from Firebase Firestore `students` collection.
  Future<List<AssessmentLearner>> loadLearners() async {
    final students = await _service.getStudents(
      classId: _requireClass(),
      schoolId: _selectedSchoolId,
    );
    return students
        .map(
          (student) => AssessmentLearner(
            id: student.id,
            name: student.name,
            initials: _initials(student.name),
            className: 'Class $_selectedClassName',
            schoolId: student.schoolId,
            classId: student.classId,
          ),
        )
        .toList();
  }

  /// Creates a live assessment session document directly in Cloud Firestore.
  Future<void> ensureSession() async {
    if (_session != null) return;
    final activeTest = await _requireTest();
    final studentIds = _learners.map((learner) => learner.id).toList();

    _session = await _service.createSession(
      schoolId: currentLearner?.schoolId ?? _selectedSchoolId,
      classId: currentLearner?.classId ?? _requireClass(),
      test: activeTest,
      studentIds: studentIds,
    );
    notifyListeners();
  }

  void setReadingCapture({
    required List<String> errorWords,
    required int durationSec,
  }) {
    final passage = _test?.passageText ?? '';
    final wordCount = passage
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    _errorWords = List.unmodifiable(errorWords);
    _readingDurationSec = durationSec;
    _readingAccuracy = Grading.readingAccuracy(
      wordsInPassage: wordCount,
      errors: errorWords.length,
    );
    _readingWordsPerMinute = Grading.wordsPerMinute(
      wordsInPassage: wordCount,
      errors: errorWords.length,
      seconds: durationSec,
    );
    notifyListeners();
  }

  void setMathAnswers(List<String> answers) {
    _mathAnswers = List.unmodifiable(answers);
    notifyListeners();
  }

  /// Saves the student reading assessment result directly into Cloud Firestore.
  Future<AssessmentResult> saveReadingResult(ResponseLevel level) async {
    final learner = _requireLearner();
    final activeTest = await _requireTest();
    await ensureSession();

    final result = await _service.saveResult(
      schoolId: learner.schoolId,
      classId: learner.classId,
      sessionId: _session!.id,
      studentId: learner.id,
      subject: Subject.reading,
      language: activeTest.language,
      level: level,
      autoLevel: Grading.levelFromPercent(_readingAccuracy ?? 0),
      durationSec: _readingDurationSec,
      wordsPerMinute: _readingWordsPerMinute,
      accuracy: _readingAccuracy,
      errorWords: _errorWords,
    );

    _completedResults.add(result);
    notifyListeners();
    return result;
  }

  /// Saves the student math assessment result directly into Cloud Firestore.
  Future<AssessmentResult> saveMathResult(
    ResponseLevel level, {
    int durationSec = 0,
  }) async {
    final learner = _requireLearner();
    final activeTest = await _requireTest();
    await ensureSession();

    final correct = _mathAnswers
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.key < activeTest.questions.length &&
              entry.value.trim().toLowerCase() ==
                  activeTest.questions[entry.key].answer.trim().toLowerCase(),
        )
        .length;

    final accuracy = Grading.mathPercent(
      itemsCorrect: correct,
      itemsTotal: activeTest.questions.length,
    );

    final result = await _service.saveResult(
      schoolId: learner.schoolId,
      classId: learner.classId,
      sessionId: _session!.id,
      studentId: learner.id,
      subject: Subject.math,
      language: activeTest.language,
      level: level,
      autoLevel: Grading.levelFromPercent(accuracy),
      durationSec: durationSec,
      accuracy: accuracy,
      itemsCorrect: correct,
      itemsTotal: activeTest.questions.length,
    );

    _completedResults.add(result);
    notifyListeners();
    return result;
  }

  Future<bool> moveToNextLearner() async {
    if (!hasNextLearner) {
      await finishSession();
      return false;
    }
    _currentLearnerIndex++;
    _resetLearnerState();
    notifyListeners();
    return true;
  }

  /// Marks the live session as completed (e.g. after the last learner, or
  /// when the teacher skips the last learner and exits).
  Future<void> finishSession() async {
    final session = _session;
    if (session == null) return;
    await _service.completeSession(session.id);
  }

  void skipCurrentLearner() {
    if (hasNextLearner) {
      _currentLearnerIndex++;
      _resetLearnerState();
      notifyListeners();
    }
  }

  void _resetLearnerState() {
    _errorWords = [];
    _readingDurationSec = 0;
    _readingAccuracy = null;
    _readingWordsPerMinute = null;
    _mathAnswers = const [];
  }

  void resetAssessment() {
    _selectedAssessment = UserChoice.none;
    _test = null;
    _session = null;
    _learners = const [];
    _currentLearnerIndex = 0;
    _errorWords = [];
    _readingDurationSec = 0;
    _readingAccuracy = null;
    _readingWordsPerMinute = null;
    _mathAnswers = const [];
    _completedResults = [];
    notifyListeners();
  }

  AssessmentLearner _requireLearner() {
    final learner = currentLearner;
    if (learner == null) {
      throw StateError(
        'Select at least one learner before starting an assessment.',
      );
    }
    return learner;
  }

  /// Fallback when only a class name like "P2-A" is known: takes the first
  /// digit in the name. Defaults to grade 3.
  static int parseGrade(String className) {
    final match = RegExp(r'\d+').firstMatch(className);
    return match == null ? 3 : int.parse(match.group(0)!);
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed
        .substring(0, trimmed.length > 2 ? 2 : trimmed.length)
        .toUpperCase();
  }
}
