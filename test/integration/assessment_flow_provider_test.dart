import 'package:flutter_test/flutter_test.dart';
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
  });

  tearDown(() {
    provider.dispose();
  });

  group('Assessment Flow Integration Tests - Provider Logic', () {
    test('Complete reading assessment flow - provider logic', () async {
      // Setup mock data
      final students = [
        Student(
          id: 's1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          name: 'Bruno Niyonsaba',
          rollNo: 1,
          status: SupportStatus.onTrack,
        ),
      ];

      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Amina walks to school with her brother.',
      );

      when(
        () => mockService.getStudents(
          classId: any(named: 'classId'),
          schoolId: any(named: 'schoolId'),
        ),
      ).thenAnswer((_) async => students);

      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => test);

      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          teacherId: any(named: 'teacherId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer(
        (_) async => AssessmentSession(
          id: 'session-1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          teacherId: 'teacher-1',
          testId: 'test-1',
          subject: Subject.reading,
          studentIds: ['s1'],
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockService.saveResult(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          sessionId: any(named: 'sessionId'),
          studentId: any(named: 'studentId'),
          teacherId: any(named: 'teacherId'),
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
      ).thenAnswer(
        (_) async => AssessmentResult(
          id: 'result-1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          sessionId: 'session-1',
          studentId: 's1',
          teacherId: 'teacher-1',
          subject: Subject.reading,
          language: Language.english,
          level: ResponseLevel.developing,
          durationSec: 30,
          createdAt: DateTime.now(),
          accuracy: 90.0,
          wordsPerMinute: 36.0,
          errorWords: ['walks'],
        ),
      );

      // Step 1: Start Assessment - Select Reading
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();
      expect(provider.test, isNotNull);
      expect(provider.test?.subject, Subject.reading);

      // Step 2: Select Learners
      final learners = await provider.loadLearners();
      provider.setLearners(learners);
      expect(provider.totalLearners, 1);
      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');

      // Step 3: Set reading capture
      provider.setReadingCapture(errorWords: ['walks'], durationSec: 30);
      expect(provider.errorWords.length, 1);
      expect(provider.readingDurationSec, 30);

      // Step 4: Save result
      await provider.saveReadingResult(ResponseLevel.developing);
      expect(provider.completedResults.length, 1);
      expect(provider.completedResults.first.studentId, 's1');
    });

    test('Complete math assessment flow - provider logic', () async {
      // Setup mock data
      final students = [
        Student(
          id: 's1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          name: 'Bruno Niyonsaba',
          rollNo: 1,
          status: SupportStatus.onTrack,
        ),
      ];

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
        ],
      );

      when(
        () => mockService.getStudents(
          classId: any(named: 'classId'),
          schoolId: any(named: 'schoolId'),
        ),
      ).thenAnswer((_) async => students);

      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => test);

      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          teacherId: any(named: 'teacherId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer(
        (_) async => AssessmentSession(
          id: 'session-1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          teacherId: 'teacher-1',
          testId: 'test-1',
          subject: Subject.math,
          studentIds: ['s1'],
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockService.saveResult(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          sessionId: any(named: 'sessionId'),
          studentId: any(named: 'studentId'),
          teacherId: any(named: 'teacherId'),
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
      ).thenAnswer(
        (_) async => AssessmentResult(
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
          itemsCorrect: 3,
          itemsTotal: 3,
        ),
      );

      // Step 1: Start Assessment - Select Math
      provider.setSelectedAssessment(UserChoice.math);
      await provider.prepareAssessment();
      expect(provider.test, isNotNull);
      expect(provider.test?.subject, Subject.math);

      // Step 2: Select Learners
      final learners = await provider.loadLearners();
      provider.setLearners(learners);
      expect(provider.totalLearners, 1);

      // Step 3: Set math answers
      provider.setMathAnswers(['correct', 'correct', 'correct']);
      expect(provider.mathAnswers.length, 3);
      expect(provider.mathAnswers.every((a) => a == 'correct'), isTrue);

      // Step 4: Save result
      await provider.saveMathResult(ResponseLevel.proficient);
      expect(provider.completedResults.length, 1);
      expect(provider.completedResults.first.studentId, 's1');
      expect(provider.completedResults.first.subject, Subject.math);
    });

    test('Multiple learners flow - provider logic', () async {
      // Setup mock data with multiple learners
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

      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Test passage.',
      );

      when(
        () => mockService.getStudents(
          classId: any(named: 'classId'),
          schoolId: any(named: 'schoolId'),
        ),
      ).thenAnswer((_) async => students);

      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => test);

      when(
        () => mockService.createSession(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          teacherId: any(named: 'teacherId'),
          test: any(named: 'test'),
          studentIds: any(named: 'studentIds'),
        ),
      ).thenAnswer(
        (_) async => AssessmentSession(
          id: 'session-1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          teacherId: 'teacher-1',
          testId: 'test-1',
          subject: Subject.reading,
          studentIds: ['s1', 's2'],
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockService.saveResult(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          sessionId: any(named: 'sessionId'),
          studentId: any(named: 'studentId'),
          teacherId: any(named: 'teacherId'),
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
      ).thenAnswer(
        (_) async => AssessmentResult(
          id: 'result-1',
          schoolId: 'gs-kigali-central',
          classId: 'class-p3-a',
          sessionId: 'session-1',
          studentId: 's1',
          teacherId: 'teacher-1',
          subject: Subject.reading,
          language: Language.english,
          level: ResponseLevel.developing,
          durationSec: 30,
          createdAt: DateTime.now(),
        ),
      );

      // Setup provider
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();
      final learners = await provider.loadLearners();
      provider.setLearners(learners);

      expect(provider.totalLearners, 2);
      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');
      expect(provider.hasNextLearner, isTrue);

      // Complete first learner
      provider.setReadingCapture(errorWords: [], durationSec: 30);
      await provider.saveReadingResult(ResponseLevel.developing);
      await provider.moveToNextLearner();

      expect(provider.currentLearner?.name, 'Fiona Uwase');
      expect(provider.hasNextLearner, isFalse);

      // Complete second learner
      provider.setReadingCapture(errorWords: ['test'], durationSec: 25);
      await provider.saveReadingResult(ResponseLevel.proficient);

      expect(provider.completedResults.length, 2);
    });

    test('Skip learner functionality - provider logic', () async {
      // Setup mock data
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

      final test = AssessmentTest(
        id: 'test-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Test passage.',
      );

      when(
        () => mockService.getStudents(
          classId: any(named: 'classId'),
          schoolId: any(named: 'schoolId'),
        ),
      ).thenAnswer((_) async => students);

      when(
        () => mockService.getTest(
          schoolId: any(named: 'schoolId'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => test);

      // Setup provider
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();
      final learners = await provider.loadLearners();
      provider.setLearners(learners);

      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');

      // Skip first learner
      provider.skipCurrentLearner();

      expect(provider.currentLearner?.name, 'Fiona Uwase');
      expect(
        provider.completedResults,
        isEmpty,
      ); // No result saved for skipped learner
    });

    test('Custom test creation flow - provider logic', () async {
      final customTest = AssessmentTest(
        id: 'custom-1',
        schoolId: 'gs-kigali-central',
        createdBy: 'teacher-1',
        title: 'Custom Reading Test',
        subject: Subject.reading,
        grade: 3,
        createdAt: DateTime.now(),
        passageText: 'Custom passage for testing.',
      );

      when(
        () => mockService.createTest(
          schoolId: any(named: 'schoolId'),
          createdBy: any(named: 'createdBy'),
          title: any(named: 'title'),
          subject: any(named: 'subject'),
          grade: any(named: 'grade'),
          language: any(named: 'language'),
          passageText: any(named: 'passageText'),
          questions: any(named: 'questions'),
        ),
      ).thenAnswer((_) async => customTest);

      // Create custom test
      final result = await provider.saveCustomTest(
        title: 'Custom Reading Test',
        subject: Subject.reading,
        grade: 3,
        passageText: 'Custom passage for testing.',
      );

      expect(result.id, 'custom-1');
      expect(provider.test?.id, 'custom-1');
      expect(provider.selectedChoice, UserChoice.reading);
    });

    test('Error handling during assessment - provider logic', () async {
      // Setup mock to throw error
      when(
        () => mockService.getStudents(
          classId: any(named: 'classId'),
          schoolId: any(named: 'schoolId'),
        ),
      ).thenThrow(Exception('Network error'));

      // Attempt to load learners
      try {
        await provider.loadLearners();
        fail('Should have thrown exception');
      } catch (e) {
        expect(e.toString(), contains('Network error'));
      }
    });
  });
}
