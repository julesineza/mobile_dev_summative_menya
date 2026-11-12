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
  AssessmentProvider({AssessmentService? service})
    : _service = service ?? AssessmentService();

  static const fallbackSchoolId = 'temporary-school';
  static const fallbackClassId = 'temporary-class-p3-a';
  static const fallbackTeacherId = 'temporary-teacher';

  final AssessmentService _service;
  UserChoice _selectedAssessment = UserChoice.none;
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
  bool _sessionPersisted = false;

  UserChoice get selectedChoice => _selectedAssessment;
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
  List<AssessmentResult> get completedResults => List.unmodifiable(_completedResults);

  void setSelectedAssessment(UserChoice assessment) {
    _selectedAssessment = assessment;
    _test = null;
    _session = null;
    _sessionPersisted = false;
    _currentLearnerIndex = 0;
    _completedResults = [];
    notifyListeners();
  }

  Future<void> prepareAssessment() async {
    final subject = _selectedAssessment == UserChoice.math
        ? Subject.math
        : Subject.reading;
    try {
      _test = await _service.getTest(
        schoolId: fallbackSchoolId,
        subject: subject,
        grade: 3,
      );
    } catch (error) {
      debugPrint('Unable to load assessment test: $error');
    }
    _test ??= _fallbackTest(subject);
    notifyListeners();
  }

  void setLearners(List<AssessmentLearner> learners) {
    _learners = List.unmodifiable(learners);
    _currentLearnerIndex = 0;
    _session = null;
    _sessionPersisted = false;
    _completedResults = [];
    notifyListeners();
  }

  Future<List<AssessmentLearner>> loadLearners() async {
    try {
      final students = await _service.getStudents(classId: fallbackClassId);
      if (students.isEmpty) {
        return _fallbackLearners();
      }
      return students
          .map(
            (student) => AssessmentLearner(
              id: student.id,
              name: student.name,
              initials: _initials(student.name),
              className: 'Class P3-A',
              schoolId: student.schoolId,
              classId: student.classId,
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Unable to load learners: $error');
      return _fallbackLearners();
    }
  }

  Future<void> ensureSession() async {
    if (_session != null) return;
    final test =
        _test ??
        _fallbackTest(
          _selectedAssessment == UserChoice.math
              ? Subject.math
              : Subject.reading,
        );
    _test ??= test;
    try {
      _session = await _service.createSession(
        schoolId: currentLearner?.schoolId ?? fallbackSchoolId,
        classId: currentLearner?.classId ?? fallbackClassId,
        teacherId: fallbackTeacherId,
        test: test,
        studentIds: _learners.map((learner) => learner.id).toList(),
      );
      _sessionPersisted = true;
    } catch (error) {
      _session = _localSession(test);
      _sessionPersisted = false;
      debugPrint(
        '[AssessmentProvider] using local session ${_session!.id}. error=$error',
      );
    }
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

  Future<AssessmentResult> saveReadingResult(ResponseLevel level) async {
    final learner = _requireLearner();
    final test = _test ?? _fallbackTest(Subject.reading);
    await ensureSession();
    try {
      final result = await _service.saveResult(
        schoolId: learner.schoolId,
        classId: learner.classId,
        sessionId: _session!.id,
        studentId: learner.id,
        teacherId: fallbackTeacherId,
        subject: Subject.reading,
        language: test.language,
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
    } catch (error) {
      debugPrint('[AssessmentProvider] saveReadingResult local save: $error');
      final localResult = AssessmentResult(
        id: 'local-res-${DateTime.now().microsecondsSinceEpoch}',
        schoolId: learner.schoolId,
        classId: learner.classId,
        sessionId: _session!.id,
        studentId: learner.id,
        teacherId: fallbackTeacherId,
        subject: Subject.reading,
        language: test.language,
        level: level,
        autoLevel: Grading.levelFromPercent(_readingAccuracy ?? 0),
        durationSec: _readingDurationSec,
        createdAt: DateTime.now(),
        wordsPerMinute: _readingWordsPerMinute,
        accuracy: _readingAccuracy,
        errorWords: _errorWords,
      );
      _completedResults.add(localResult);
      notifyListeners();
      return localResult;
    }
  }

  Future<AssessmentResult> saveMathResult(ResponseLevel level) async {
    final learner = _requireLearner();
    final test = _test ?? _fallbackTest(Subject.math);
    await ensureSession();
    final correct = _mathAnswers
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.key < test.questions.length &&
              entry.value.trim().toLowerCase() ==
                  test.questions[entry.key].answer.trim().toLowerCase(),
        )
        .length;
    final accuracy = Grading.mathPercent(
      itemsCorrect: correct,
      itemsTotal: test.questions.length,
    );
    try {
      final result = await _service.saveResult(
        schoolId: learner.schoolId,
        classId: learner.classId,
        sessionId: _session!.id,
        studentId: learner.id,
        teacherId: fallbackTeacherId,
        subject: Subject.math,
        language: test.language,
        level: level,
        autoLevel: Grading.levelFromPercent(accuracy),
        durationSec: 0,
        accuracy: accuracy,
        itemsCorrect: correct,
        itemsTotal: test.questions.length,
      );
      _completedResults.add(result);
      notifyListeners();
      return result;
    } catch (error) {
      debugPrint('[AssessmentProvider] saveMathResult local save: $error');
      final localResult = AssessmentResult(
        id: 'local-res-${DateTime.now().microsecondsSinceEpoch}',
        schoolId: learner.schoolId,
        classId: learner.classId,
        sessionId: _session!.id,
        studentId: learner.id,
        teacherId: fallbackTeacherId,
        subject: Subject.math,
        language: test.language,
        level: level,
        autoLevel: Grading.levelFromPercent(accuracy),
        durationSec: 0,
        createdAt: DateTime.now(),
        accuracy: accuracy,
        itemsCorrect: correct,
        itemsTotal: test.questions.length,
      );
      _completedResults.add(localResult);
      notifyListeners();
      return localResult;
    }
  }

  Future<bool> moveToNextLearner() async {
    if (!hasNextLearner) {
      debugPrint(
        '[AssessmentProvider] completing final session=${_session?.id}',
      );
      if (_session != null) {
        await _service.completeSession(_session!.id);
      }
      return false;
    }
    debugPrint(
      '[AssessmentProvider] moving from learner index=$_currentLearnerIndex',
    );
    _currentLearnerIndex++;
    _errorWords = [];
    _readingDurationSec = 0;
    _readingAccuracy = null;
    _readingWordsPerMinute = null;
    _mathAnswers = const [];
    notifyListeners();
    return true;
  }

  bool skipCurrentLearner() {
    if (!hasNextLearner) return false;
    _currentLearnerIndex++;
    _errorWords = [];
    _readingDurationSec = 0;
    _readingAccuracy = null;
    _readingWordsPerMinute = null;
    _mathAnswers = const [];
    notifyListeners();
    return true;
  }

  void resetAssessment() {
    _selectedAssessment = UserChoice.none;
    _test = null;
    _session = null;
    _sessionPersisted = false;
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

  AssessmentSession _localSession(AssessmentTest test) {
    final now = DateTime.now();
    return AssessmentSession(
      id: 'local-${now.microsecondsSinceEpoch}',
      schoolId: currentLearner?.schoolId ?? fallbackSchoolId,
      classId: currentLearner?.classId ?? fallbackClassId,
      teacherId: fallbackTeacherId,
      testId: test.id,
      subject: test.subject,
      language: test.language,
      studentIds: _learners.map((learner) => learner.id).toList(),
      createdAt: now,
    );
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

  List<AssessmentLearner> _fallbackLearners() {
    return [
      AssessmentLearner(
        id: 'temporary-student-bruno',
        name: 'Bruno Niyonsaba',
        initials: 'BN',
        className: 'Class P3-A',
        schoolId: fallbackSchoolId,
        classId: fallbackClassId,
      ),
      AssessmentLearner(
        id: 'temporary-student-fiona',
        name: 'Fiona Uwase',
        initials: 'FU',
        className: 'Class P3-A',
        schoolId: fallbackSchoolId,
        classId: fallbackClassId,
      ),
      AssessmentLearner(
        id: 'temporary-student-aliane',
        name: 'Aliane Umutoni',
        initials: 'AU',
        className: 'Class P3-A',
        schoolId: fallbackSchoolId,
        classId: fallbackClassId,
      ),
      AssessmentLearner(
        id: 'temporary-student-cynthia',
        name: 'Cynthia Gisa',
        initials: 'CG',
        className: 'Class P3-A',
        schoolId: fallbackSchoolId,
        classId: fallbackClassId,
      ),
    ];
  }

  AssessmentTest _fallbackTest(Subject subject) {
    if (subject == Subject.math) {
      return AssessmentTest(
        id: 'fallback-math-level-2',
        schoolId: fallbackSchoolId,
        createdBy: fallbackTeacherId,
        title: 'Math Quick Check',
        subject: Subject.math,
        grade: 3,
        createdAt: DateTime.now(),
        questions: const [
          TestQuestion(prompt: '12 ÷ 3 = ?', answer: '4'),
          TestQuestion(prompt: '6 + 7 = ?', answer: '13'),
          TestQuestion(prompt: '5 × 2 = ?', answer: '10'),
        ],
      );
    }
    return AssessmentTest(
      id: 'fallback-reading-level-2',
      schoolId: fallbackSchoolId,
      createdBy: fallbackTeacherId,
      title: 'English Reading Level 2',
      subject: Subject.reading,
      grade: 3,
      createdAt: DateTime.now(),
      passageText: 'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.',
    );
  }
}

