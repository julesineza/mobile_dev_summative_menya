import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/failure.dart';
import 'package:mobile_dev_summative_menya/core/grading.dart';
import 'package:mobile_dev_summative_menya/models/assessment_result.dart';
import 'package:mobile_dev_summative_menya/models/assessment_session.dart';
import 'package:mobile_dev_summative_menya/models/assessment_test.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:mobile_dev_summative_menya/services/assessment_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAssessmentService extends Mock implements AssessmentService {}

void main() {
  late MockAssessmentService mockService;
  late AssessmentProvider provider;

  setUpAll(() {
    registerFallbackValue(
      AssessmentTest(
        id: 'fallback',
        schoolId: 'fallback',
        createdBy: 'fallback',
        title: 'Fallback',
        subject: Subject.reading,
        grade: 1,
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(Subject.reading);
    registerFallbackValue(Subject.math);
    registerFallbackValue(Language.english);
    registerFallbackValue(ResponseLevel.developing);
    registerFallbackValue(UserChoice.reading);
  });

  setUp(() {
    mockService = MockAssessmentService();
    provider = AssessmentProvider(service: mockService);
    // The provider has no hardcoded class any more; tests pick one.
    provider.setSelectedClass(
      name: 'P3-A',
      id: 'class-p3-a',
      schoolId: 'gs-kigali-central',
      grade: 3,
    );
  });

  tearDown(() {
    provider.dispose();
  });

  group('AssessmentProvider Unit Tests', () {
    test('initial state is correct (no hardcoded class)', () {
      final provider = AssessmentProvider(service: mockService);
      expect(provider.selectedChoice, UserChoice.none);
      expect(provider.hasClass, isFalse);
      expect(provider.selectedClassName, '');
      expect(provider.selectedClassId, isNull);
      expect(provider.test, isNull);
      expect(provider.session, isNull);
      expect(provider.learners, isEmpty);
      expect(provider.currentLearnerIndex, 0);
      expect(provider.totalLearners, 0);
      expect(provider.currentLearner, isNull);
      expect(provider.hasNextLearner, isFalse);
      expect(provider.errorWords, isEmpty);
      expect(provider.readingDurationSec, 0);
      expect(provider.readingAccuracy, isNull);
      expect(provider.readingWordsPerMinute, isNull);
      expect(provider.mathAnswers, isEmpty);
      expect(provider.completedResults, isEmpty);
    });

    test('setSelectedAssessment updates state and resets', () {
      provider.setSelectedAssessment(UserChoice.reading);
      expect(provider.selectedChoice, UserChoice.reading);

      provider.setSelectedAssessment(UserChoice.math);
      expect(provider.selectedChoice, UserChoice.math);

      provider.setSelectedAssessment(UserChoice.none);
      expect(provider.selectedChoice, UserChoice.none);
    });

    test('setSelectedClass updates class info and resets learners', () {
      provider.setSelectedClass(name: 'P2-A', id: 'class-p2-a');
      expect(provider.selectedClassName, 'P2-A');
      expect(provider.selectedClassId, 'class-p2-a');
    });

    test('syncFromClass uses the real class document', () {
      provider.syncFromClass(
        id: 'doc-123',
        name: 'P1-A',
        schoolId: 'school-1',
        grade: 1,
      );
      expect(provider.hasClass, isTrue);
      expect(provider.selectedClassName, 'P1-A');
      expect(provider.selectedClassId, 'doc-123');
      expect(provider.selectedSchoolId, 'school-1');
      expect(provider.selectedGrade, 1);
    });

    test('clearClass forgets the class when the teacher has none', () {
      provider.syncFromClass(id: 'doc-123', name: 'P1-A', schoolId: 's1');
      provider.clearClass();
      expect(provider.hasClass, isFalse);
      expect(provider.selectedClassId, isNull);
    });

    test('without a class, loading a test fails with a clear message', () {
      final provider = AssessmentProvider(service: mockService);
      provider.setSelectedAssessment(UserChoice.reading);
      expect(
        provider.prepareAssessment,
        throwsA(
          isA<Failure>().having(
            (f) => f.message,
            'message',
            'Create or choose a class first.',
          ),
        ),
      );
    });

    test('setLearners updates learner list and resets index', () {
      final learners = [
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
        const AssessmentLearner(
          id: 's2',
          name: 'Fiona Uwase',
          initials: 'FU',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ];

      provider.setLearners(learners);
      expect(provider.learners.length, 2);
      expect(provider.totalLearners, 2);
      expect(provider.currentLearnerIndex, 0);
      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');
      expect(provider.hasNextLearner, isTrue);
    });

    test('setReadingCapture calculates accuracy and WPM', () {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.',
      );
      provider.setCustomTest(test);

      provider.setReadingCapture(
        errorWords: ['walks', 'tree'],
        durationSec: 40,
      );

      expect(provider.errorWords.length, 2);
      expect(provider.readingDurationSec, 40);
      expect(provider.readingAccuracy, isNotNull);
      expect(provider.readingWordsPerMinute, isNotNull);
    });

    test('setMathAnswers updates math answers', () {
      provider.setMathAnswers(['4', '13', '10', '9']);
      expect(provider.mathAnswers.length, 4);
      expect(provider.mathAnswers[0], '4');
    });

    test('moveToNextLearner advances index and resets state', () async {
      final learners = [
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
        const AssessmentLearner(
          id: 's2',
          name: 'Fiona Uwase',
          initials: 'FU',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ];
      provider.setLearners(learners);

      provider.setReadingCapture(errorWords: ['walks'], durationSec: 30);
      expect(provider.errorWords.length, 1);

      final hasNext = await provider.moveToNextLearner();
      expect(hasNext, isTrue);
      expect(provider.currentLearnerIndex, 1);
      expect(provider.currentLearner?.name, 'Fiona Uwase');
      expect(provider.hasNextLearner, isFalse);
      expect(provider.errorWords, isEmpty);
      expect(provider.readingDurationSec, 0);
    });

    test('moveToNextLearner returns false at end', () async {
      final learners = [
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ];
      provider.setLearners(learners);

      final hasNext = await provider.moveToNextLearner();
      expect(hasNext, isFalse);
    });

    test('skipCurrentLearner advances without saving', () {
      final learners = [
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
        const AssessmentLearner(
          id: 's2',
          name: 'Fiona Uwase',
          initials: 'FU',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ];
      provider.setLearners(learners);

      provider.skipCurrentLearner();
      expect(provider.currentLearnerIndex, 1);
      expect(provider.currentLearner?.name, 'Fiona Uwase');
    });

    test('resetAssessment clears all state', () {
      provider.setSelectedAssessment(UserChoice.reading);
      provider.setSelectedClass(name: 'P2-A', id: 'class-p2-a');
      provider.setLearners([
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P2-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p2-a',
        ),
      ]);
      provider.setReadingCapture(errorWords: ['walks'], durationSec: 30);

      provider.resetAssessment();

      expect(provider.selectedChoice, UserChoice.none);
      expect(provider.learners, isEmpty);
      expect(provider.currentLearnerIndex, 0);
      expect(provider.errorWords, isEmpty);
      expect(provider.readingDurationSec, 0);
    });

    test('saveCustomTest creates and sets test', () async {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Custom Reading',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Test passage',
      );

      when(
        () => mockService.createTest(
          schoolId: any(named: 'schoolId'),
          title: any(named: 'title'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
          language: any(named: 'language'),
          passageText: any(named: 'passageText'),
          questions: any(named: 'questions'),
        ),
      ).thenAnswer((_) async => test);

      final result = await provider.saveCustomTest(
        title: 'Custom Reading',
        subject: Subject.reading,
        grade: 3,
        passageText: 'Test passage',
      );

      expect(result.id, 'test-1');
      expect(provider.test?.id, 'test-1');
      expect(provider.selectedChoice, UserChoice.reading);
    });

    test('setCustomTest updates test and assessment type', () {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Math Test',
        subject: Subject.math,
        grade: 3,
        createdAt: DateTime.now(),
        questions: const [TestQuestion(prompt: '2+2=?', answer: '4')],
      );

      provider.setCustomTest(test);
      expect(provider.test?.id, 'test-1');
      expect(provider.selectedChoice, UserChoice.math);
    });

    test('prepareAssessment loads test from service', () async {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Test passage',
      );

      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => test);

      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();

      expect(provider.test?.id, 'test-1');
      expect(provider.test?.subject, Subject.reading);
    });

    test('loadLearners returns learners from service', () async {
      final students = [
        Student(
          id: 's1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          name: 'Bruno Niyonsaba',
          rollNo: 1,
          status: SupportStatus.onTrack,
        ),
        Student(
          id: 's2',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          name: 'Fiona Uwase',
          rollNo: 2,
          status: SupportStatus.onTrack,
        ),
      ];

      when(
        () => mockService.getStudents(
          classId: any(named: 'classId'),
          schoolId: any(named: 'schoolId'),
        ),
      ).thenAnswer((_) async => students);

      final learners = await provider.loadLearners();
      expect(learners.length, 2);
      expect(learners[0].name, 'Bruno Niyonsaba');
      expect(learners[1].name, 'Fiona Uwase');
    });

    test('ensureSession creates session when test exists', () async {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Test passage',
      );

      final session = AssessmentSession(
        id: 'session-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        teacherId: 'teacher-1',
        testId: 'test-1',
        subject: Subject.reading,
        studentIds: ['s1', 's2'],
        createdAt: DateTime.now(),
      );

      provider.setCustomTest(test);
      provider.setLearners([
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
        const AssessmentLearner(
          id: 's2',
          name: 'Fiona Uwase',
          initials: 'FU',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ]);

      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer((_) async => session);

      await provider.ensureSession();
      expect(provider.session?.id, 'session-1');
    });

    test('saveReadingResult saves result and advances', () async {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.',
      );

      final session = AssessmentSession(
        id: 'session-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        teacherId: 'teacher-1',
        testId: 'test-1',
        subject: Subject.reading,
        studentIds: ['s1'],
        createdAt: DateTime.now(),
      );

      final result = AssessmentResult(
        id: 'result-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        sessionId: 'session-1',
        studentId: 's1',
        teacherId: 'teacher-1',
        subject: Subject.reading,
        language: Language.english,
        level: ResponseLevel.developing,
        durationSec: 40,
        createdAt: DateTime.now(),
        accuracy: 90.0,
        wordsPerMinute: 36.0,
        errorWords: ['walks', 'tree'],
      );

      provider.setCustomTest(test);
      provider.setLearners([
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ]);
      provider.setReadingCapture(
        errorWords: ['walks', 'tree'],
        durationSec: 40,
      );

      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer((_) async => session);

      when(
        () => mockService.saveResult(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          sessionId: any(named: 'sessionId'),
          studentId: any(named: 'studentId'),
          subject: any(named: 'subject'),
          language: any(named: 'language'),
          level: any(named: 'level'),
          autoLevel: any(named: 'autoLevel'),
          durationSec: any(named: 'durationSec'),
          wordsPerMinute: any(named: 'wordsPerMinute'),
          accuracy: any(named: 'accuracy'),
          errorWords: any(named: 'errorWords'),
          itemsCorrect: any(named: 'itemsCorrect'),
          itemsTotal: any(named: 'itemsTotal'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => result);

      final savedResult = await provider.saveReadingResult(
        ResponseLevel.developing,
      );

      expect(savedResult.studentId, 's1');
      expect(savedResult.level, ResponseLevel.developing);
      expect(provider.completedResults.length, 1);
    });

    test('saveMathResult saves result with correct calculation', () async {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Math Test',
        subject: Subject.math,
        grade: 3,
        createdAt: DateTime.now(),
        questions: const [
          TestQuestion(prompt: '12 ÷ 3 = ?', answer: '4'),
          TestQuestion(prompt: '6 + 7 = ?', answer: '13'),
          TestQuestion(prompt: '5 × 2 = ?', answer: '10'),
          TestQuestion(prompt: '18 - 9 = ?', answer: '9'),
        ],
      );

      final session = AssessmentSession(
        id: 'session-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        teacherId: 'teacher-1',
        testId: 'test-1',
        subject: Subject.math,
        studentIds: ['s1'],
        createdAt: DateTime.now(),
      );

      final result = AssessmentResult(
        id: 'result-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        sessionId: 'session-1',
        studentId: 's1',
        teacherId: 'teacher-1',
        subject: Subject.math,
        language: Language.english,
        level: ResponseLevel.proficient,
        durationSec: 60,
        createdAt: DateTime.now(),
        accuracy: 100.0,
        itemsCorrect: 4,
        itemsTotal: 4,
      );

      provider.setCustomTest(test);
      provider.setLearners([
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
        ),
      ]);
      provider.setMathAnswers(['4', '13', '10', '9']);

      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer((_) async => session);

      when(
        () => mockService.saveResult(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          sessionId: any(named: 'sessionId'),
          studentId: any(named: 'studentId'),
          subject: any(named: 'subject'),
          language: any(named: 'language'),
          level: any(named: 'level'),
          autoLevel: any(named: 'autoLevel'),
          durationSec: any(named: 'durationSec'),
          wordsPerMinute: any(named: 'wordsPerMinute'),
          accuracy: any(named: 'accuracy'),
          errorWords: any(named: 'errorWords'),
          itemsCorrect: any(named: 'itemsCorrect'),
          itemsTotal: any(named: 'itemsTotal'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => result);

      final savedResult = await provider.saveMathResult(
        ResponseLevel.proficient,
        durationSec: 60,
      );

      expect(savedResult.studentId, 's1');
      expect(savedResult.level, ResponseLevel.proficient);
      expect(provider.completedResults.length, 1);
    });
  });

  group('AssessmentService Unit Tests', () {
    test('supportStatusFromLevel maps levels correctly', () {
      expect(
        supportStatusFromLevel(ResponseLevel.struggling),
        SupportStatus.needsSupport,
      );
      expect(
        supportStatusFromLevel(ResponseLevel.developing),
        SupportStatus.watch,
      );
      expect(
        supportStatusFromLevel(ResponseLevel.proficient),
        SupportStatus.onTrack,
      );
    });

    test('AssessmentTest.wordCount calculates correctly', () {
      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.',
      );

      expect(test.wordCount, 20);
    });

    test('AssessmentResult.teacherOverrode detects override', () {
      final result = AssessmentResult(
        id: 'result-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        sessionId: 'session-1',
        studentId: 's1',
        teacherId: 'teacher-1',
        subject: Subject.reading,
        language: Language.english,
        level: ResponseLevel.developing,
        autoLevel: ResponseLevel.proficient,
        durationSec: 40,
        createdAt: DateTime.now(),
      );

      expect(result.teacherOverrode, isTrue);
    });

    test('AssessmentResult.teacherOverrode false when same', () {
      final result = AssessmentResult(
        id: 'result-1',
        schoolId: 'gs-kigali-central',
        classId: 'class-p3-a',
        sessionId: 'session-1',
        studentId: 's1',
        teacherId: 'teacher-1',
        subject: Subject.reading,
        language: Language.english,
        level: ResponseLevel.developing,
        autoLevel: ResponseLevel.developing,
        durationSec: 40,
        createdAt: DateTime.now(),
      );

      expect(result.teacherOverrode, isFalse);
    });
  });

  group('Grading Logic Tests', () {
    test('Calculates reading accuracy correctly', () {
      // 20 words, 2 errors -> 18/20 = 90%
      final accuracy = Grading.readingAccuracy(wordsInPassage: 20, errors: 2);
      expect(accuracy, 90.0);
    });

    test('Calculates words per minute correctly', () {
      // 20 words, 2 errors = 18 correct words. In 30 seconds = 36 WPM.
      final wpm = Grading.wordsPerMinute(
        wordsInPassage: 20,
        errors: 2,
        seconds: 30,
      );
      expect(wpm, 36.0);
    });

    test('Assigns correct response levels based on cutoffs', () {
      expect(Grading.levelFromPercent(95.0), ResponseLevel.proficient);
      expect(Grading.levelFromPercent(85.0), ResponseLevel.proficient);
      expect(Grading.levelFromPercent(84.9), ResponseLevel.developing);
      expect(Grading.levelFromPercent(60.0), ResponseLevel.developing);
      expect(Grading.levelFromPercent(59.9), ResponseLevel.struggling);
      expect(Grading.levelFromPercent(30.0), ResponseLevel.struggling);
    });

    test('Calculates math percent correctly', () {
      expect(Grading.mathPercent(itemsCorrect: 3, itemsTotal: 4), 75.0);
      expect(Grading.mathPercent(itemsCorrect: 0, itemsTotal: 4), 0.0);
      expect(Grading.mathPercent(itemsCorrect: 4, itemsTotal: 4), 100.0);
      expect(Grading.mathPercent(itemsCorrect: 0, itemsTotal: 0), 0.0);
    });
  });

  group('Assessment bug fixes', () {
    AssessmentTest makeTest({
      String id = 'custom-1',
      Subject subject = Subject.reading,
      int grade = 3,
    }) => AssessmentTest(
      id: id,
      schoolId: 'school-1',
      createdBy: 'teacher-1',
      title: 'Custom',
      subject: subject,
      grade: grade,
      createdAt: DateTime(2026),
      passageText: 'A custom passage.',
    );

    test('custom test is kept when the same subject is chosen', () {
      provider.setCustomTest(makeTest());
      provider.setSelectedAssessment(UserChoice.reading);
      expect(provider.test?.id, 'custom-1');
    });

    test('custom test is dropped when another subject is chosen', () {
      provider.setCustomTest(makeTest());
      provider.setSelectedAssessment(UserChoice.math);
      expect(provider.test, isNull);
    });

    test('prepareAssessment does not replace a matching custom test', () async {
      provider.setCustomTest(makeTest());
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();
      expect(provider.test?.id, 'custom-1');
      verifyNever(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      );
    });

    test('the real class grade is used to load the default test', () async {
      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => makeTest(id: 'default', grade: 5));

      provider.setSelectedClass(
        name: 'Lions',
        id: 'class-lions',
        schoolId: 'school-1',
        grade: 5,
      );
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();

      verify(
        () => mockService.getTest(
          schoolId: 'school-1',
          subject: Subject.reading,
          grade: 5,
        ),
      ).called(1);
    });

    test('changing to a class of another grade drops the old test', () {
      provider.setCustomTest(makeTest(grade: 3));
      provider.setSelectedClass(name: 'P1-A', id: 'c1', grade: 1);
      expect(provider.test, isNull);
    });

    test('parseGrade reads the number from a class name', () {
      expect(AssessmentProvider.parseGrade('P1-A'), 1);
      expect(AssessmentProvider.parseGrade('P5-B'), 5);
      expect(AssessmentProvider.parseGrade('Lions'), 3);
    });

    test('saving fails with an error instead of crashing when the test '
        'cannot be loaded', () async {
      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenThrow(Exception('offline'));
      provider.setSelectedAssessment(UserChoice.reading);
      provider.setLearners(const [
        AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'school-1',
          classId: 'class-p3-a',
        ),
      ]);

      expect(
        () => provider.saveReadingResult(ResponseLevel.developing),
        throwsA(isA<Exception>()),
      );
    });

    test('finishSession completes the open session', () async {
      final session = AssessmentSession(
        id: 'session-9',
        schoolId: 'school-1',
        classId: 'class-p3-a',
        teacherId: 'teacher-1',
        testId: 'custom-1',
        subject: Subject.reading,
        studentIds: const ['s1'],
        createdAt: DateTime(2026),
      );
      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer((_) async => session);
      when(
        () => mockService.completeSession(any()),
      ).thenAnswer((_) async {});

      provider.setCustomTest(makeTest());
      await provider.ensureSession();
      await provider.finishSession();

      verify(() => mockService.completeSession('session-9')).called(1);
    });

    test('finishSession does nothing without a session', () async {
      await provider.finishSession();
      verifyNever(() => mockService.completeSession(any()));
    });
  });
}
