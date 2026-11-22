import 'dart:async';

import 'package:flutter/foundation.dart';

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
  AssessmentProvider({AssessmentService? service, String? initialClassName})
    : _service = service ?? AssessmentService() {
    if (initialClassName != null && initialClassName.isNotEmpty) {
      _selectedClassName = initialClassName;
      _selectedClassId = _resolveClassId(initialClassName);
    }
  }

  static const fallbackSchoolId = 'gs-kigali-central';
  static const fallbackClassId = 'class-p3-a';
  static const fallbackTeacherId = 'teacher-1';

  final AssessmentService _service;
  UserChoice _selectedAssessment = UserChoice.none;
  String _selectedClassName = 'P3-A';
  String _selectedClassId = fallbackClassId;
  String _selectedSchoolId = fallbackSchoolId;
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
  String get selectedClassId => _selectedClassId;
  String get selectedSchoolId => _selectedSchoolId;
  AssessmentTest? get test => _test;
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

  static String _resolveClassId(String className) {
    final sanitized = className.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return 'class-$sanitized';
  }

  /// Called by [ChangeNotifierProxyProvider] when [SettingsProvider.activeClass] changes.
  /// Updates the selected class without firing a full reset.
  void syncClassFromSettings(String className) {
    if (className.isEmpty || _selectedClassName == className) return;
    _selectedClassName = className;
    _selectedClassId = _resolveClassId(className);
    notifyListeners();
  }

  void syncFromClass({
    required String id,
    required String name,
    required String schoolId,
  }) {
    if (id != _selectedClassId) {
      _learners = const [];
      _currentLearnerIndex = 0;
      _session = null;
    }
    _selectedClassId = id;
    _selectedClassName = name;
    _selectedSchoolId = schoolId;
  }

  void setSelectedAssessment(UserChoice assessment) {
    _selectedAssessment = assessment;
    _test = null;
    _session = null;
    _currentLearnerIndex = 0;
    _completedResults = [];
    notifyListeners();
  }

  Future<void> prepareAssessment() async {
    if (_test != null) {
      notifyListeners();
      return;
    }
    final subject = _selectedAssessment == UserChoice.math
        ? Subject.math
        : Subject.reading;

    final grade = _parseGrade(_selectedClassName);
    _test = await _service.getTest(
      schoolId: _selectedSchoolId,
      subject: subject,
      grade: grade,
    );
    notifyListeners();
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
      createdBy: fallbackTeacherId,
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

  void setSelectedClass({required String name, required String id}) {
    _selectedClassName = name;
    _selectedClassId = id;
    _learners = const [];
    _currentLearnerIndex = 0;
    _session = null;
    notifyListeners();
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
      classId: _selectedClassId,
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
    if (_test == null) await prepareAssessment();

    final activeTest = _test!;
    final studentIds = _learners.map((learner) => learner.id).toList();

    _session = await _service.createSession(
      schoolId: currentLearner?.schoolId ?? _selectedSchoolId,
      classId: currentLearner?.classId ?? _selectedClassId,
      teacherId: fallbackTeacherId,
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
    if (_test == null) await prepareAssessment();
    final activeTest = _test!;
    await ensureSession();

    final result = await _service.saveResult(
      schoolId: learner.schoolId,
      classId: learner.classId,
      sessionId: _session!.id,
      studentId: learner.id,
      teacherId: fallbackTeacherId,
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
    if (_test == null) await prepareAssessment();
    final activeTest = _test!;
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
      teacherId: fallbackTeacherId,
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
      if (_session != null) {
        await _service.completeSession(_session!.id);
      }
      return false;
    }
    _currentLearnerIndex++;
    _resetLearnerState();
    notifyListeners();
    return true;
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

  int _parseGrade(String className) {
    if (className.contains('1')) return 1;
    if (className.contains('2')) return 2;
    return 3;
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
