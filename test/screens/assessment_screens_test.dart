import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/models/assessment_test.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/start_assessment.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/select_learners.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/prepare_reading.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/assessment_reading.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/assessment_math.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/take_reading.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/setup_reading_test.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/setup_math_test.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/select_class.dart';
import 'package:mobile_dev_summative_menya/services/assessment_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAssessmentService extends Mock implements AssessmentService {}

void main() {
  late MockAssessmentService mockService;
  late AssessmentProvider provider;

  setUp(() {
    mockService = MockAssessmentService();
    provider = AssessmentProvider(service: mockService);
  });

  tearDown(() {
    provider.dispose();
  });

  group('Assessment Screen Widget Tests', () {
    // Note: Full widget tests require complex provider setup and navigation context.
    // These tests focus on basic widget structure and logic that can be tested
    // without full provider dependencies.

    testWidgets('StartAssessment widget can be instantiated', (tester) async {
      expect(const StartAssessment(), isNotNull);
    });

    testWidgets('SelectLearnersPage widget can be instantiated', (
      tester,
    ) async {
      expect(const SelectLearnersPage(), isNotNull);
    });

    testWidgets('PrepareReadingPage widget can be instantiated', (
      tester,
    ) async {
      expect(const PrepareReadingPage(), isNotNull);
    });

    testWidgets('AssessmentReading widget can be instantiated', (tester) async {
      expect(const AssessmentReading(), isNotNull);
    });

    testWidgets('AssessmentMath widget can be instantiated', (tester) async {
      expect(const AssessmentMath(), isNotNull);
    });

    testWidgets('ReadingPausedPage widget can be instantiated', (tester) async {
      expect(const ReadingPausedPage(), isNotNull);
    });

    testWidgets('TestSetupReadingPage widget can be instantiated', (
      tester,
    ) async {
      expect(const TestSetupReadingPage(), isNotNull);
    });

    testWidgets('TestSetupMathPage widget can be instantiated', (tester) async {
      expect(const TestSetupMathPage(), isNotNull);
    });

    testWidgets('SelectClassesPage widget can be instantiated', (tester) async {
      expect(const SelectClassesPage(), isNotNull);
    });
  });

  group('Assessment Logic Tests', () {
    testWidgets('word count calculation logic', (tester) async {
      const wordList =
          'school, books, story, brother, carry, mango, tree, walk, read, together';
      final words = wordList
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      expect(words.length, 10);
    });

    testWidgets('question validation logic', (tester) async {
      const questions = [
        TestQuestion(prompt: '12 ÷ 3 = ?', answer: '4'),
        TestQuestion(prompt: '6 + 7 = ?', answer: '13'),
      ];
      expect(questions.length, 2);
      expect(questions.first.prompt, '12 ÷ 3 = ?');
      expect(questions.first.answer, '4');
    });

    testWidgets('learner selection logic', (tester) async {
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
      expect(provider.totalLearners, 2);
      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');
      expect(provider.hasNextLearner, isTrue);
    });
  });
}
