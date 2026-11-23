import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/grading.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';

/// Sample learners used across widget tests (mirror what Firestore would return).
final _sampleLearners = [
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

// ─────────────────────────────────────────────────────────────────────────────
void main() {
  // ── Grading logic (pure, no Flutter) ───────────────────────────────────────
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
  });

  // ── Provider unit tests (no Flutter widget tree needed) ───────────────────
  group('AssessmentProvider Unit Tests', () {
    test('Flow through multiple learners with reading capture', () async {
      final provider = AssessmentProvider();
      provider.setSelectedClass(
        name: 'P3-A',
        id: 'class-p3-a',
        schoolId: 'gs-kigali-central',
        grade: 3,
      );
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();

      // Service returns a built-in default test when Firestore is unavailable.
      expect(provider.test, isNotNull);
      expect(provider.test?.subject, Subject.reading);

      provider.setLearners(_sampleLearners);
      expect(provider.totalLearners, 2);
      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');
      expect(provider.hasNextLearner, isTrue);

      // Record reading for learner 1
      provider.setReadingCapture(
        errorWords: ['walks', 'tree'],
        durationSec: 40,
      );

      expect(provider.errorWords.length, 2);
      expect(provider.readingDurationSec, 40);
      expect(provider.readingAccuracy, isNotNull);
      expect(provider.readingWordsPerMinute, isNotNull);

      // Save result (Firestore is null in tests → service skips the write but still returns the result).
      final result1 = await provider.saveReadingResult(
        ResponseLevel.developing,
      );
      expect(result1.studentId, 's1');
      expect(result1.level, ResponseLevel.developing);

      // Advance to learner 2
      final hasNext = await provider.moveToNextLearner();
      expect(hasNext, isTrue);
      expect(provider.currentLearner?.name, 'Fiona Uwase');
      expect(provider.currentLearnerIndex, 1);
      expect(provider.hasNextLearner, isFalse);

      provider.setReadingCapture(errorWords: [], durationSec: 25);
      final result2 = await provider.saveReadingResult(
        ResponseLevel.proficient,
      );
      expect(result2.studentId, 's2');
      expect(result2.level, ResponseLevel.proficient);

      // Past the last learner
      final finished = await provider.moveToNextLearner();
      expect(finished, isFalse);
    });
  });

  // ── Widget (integration) tests ─────────────────────────────────────────────
  // Widget and integration tests have been moved to dedicated test files:
  // - test/screens/assessment_screens_test.dart (widget tests for individual screens)
  // - test/integration/assessment_flow_integration_test.dart (end-to-end flow tests)
  // - test/providers/assessment_provider_test.dart (comprehensive provider unit tests)
  //
  // These files provide better organization and more comprehensive coverage
  // of the assessment module functionality.
  group('Full Member 3 Flow Widget Tests', () {
    // Tests moved to dedicated files for better organization
  });
}
