import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/app_routes.dart';
import 'package:mobile_dev_summative_menya/core/grading.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:provider/provider.dart';

void main() {
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
      expect(Grading.levelFromPercent(90.0), ResponseLevel.proficient);
      expect(Grading.levelFromPercent(89.9), ResponseLevel.developing);
      expect(Grading.levelFromPercent(70.0), ResponseLevel.developing);
      expect(Grading.levelFromPercent(69.9), ResponseLevel.struggling);
      expect(Grading.levelFromPercent(30.0), ResponseLevel.struggling);
    });
  });

  group('AssessmentProvider Unit Tests', () {
    test('Flow through multiple learners with reading capture', () async {
      final provider = AssessmentProvider();
      provider.setSelectedAssessment(UserChoice.reading);
      await provider.prepareAssessment();

      expect(provider.test, isNotNull);
      expect(provider.test?.subject, Subject.reading);

      final learners = [
        const AssessmentLearner(
          id: 's1',
          name: 'Bruno Niyonsaba',
          initials: 'BN',
          className: 'Class P3-A',
          schoolId: 'school-1',
          classId: 'class-1',
        ),
        const AssessmentLearner(
          id: 's2',
          name: 'Fiona Uwase',
          initials: 'FU',
          className: 'Class P3-A',
          schoolId: 'school-1',
          classId: 'class-1',
        ),
      ];

      provider.setLearners(learners);
      expect(provider.totalLearners, 2);
      expect(provider.currentLearner?.name, 'Bruno Niyonsaba');
      expect(provider.hasNextLearner, isTrue);

      // Record reading for student 1
      provider.setReadingCapture(
        errorWords: ['walks', 'tree'],
        durationSec: 40,
      );

      expect(provider.errorWords.length, 2);
      expect(provider.readingDurationSec, 40);
      expect(provider.readingAccuracy, isNotNull);
      expect(provider.readingWordsPerMinute, isNotNull);

      // Save reading result - offline tolerant
      final result1 = await provider.saveReadingResult(ResponseLevel.developing);
      expect(result1.studentId, 's1');
      expect(result1.level, ResponseLevel.developing);

      // Advance to next student
      final hasNext = await provider.moveToNextLearner();
      expect(hasNext, isTrue);
      expect(provider.currentLearner?.name, 'Fiona Uwase');
      expect(provider.currentLearnerIndex, 1);
      expect(provider.hasNextLearner, isFalse);

      // Student 2 has 0 errors
      provider.setReadingCapture(
        errorWords: [],
        durationSec: 25,
      );
      final result2 = await provider.saveReadingResult(ResponseLevel.proficient);
      expect(result2.studentId, 's2');
      expect(result2.level, ResponseLevel.proficient);

      // Advance past final student
      final finished = await provider.moveToNextLearner();
      expect(finished, isFalse);
    });
  });

  group('Full Member 3 Flow Widget Tests', () {
    testWidgets('Complete reading journey: start -> select -> prepare -> check -> review',
        (WidgetTester tester) async {
      final provider = AssessmentProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AssessmentProvider>.value(
          value: provider,
          child: MaterialApp(
            initialRoute: AppRoutes.start_assessment,
            routes: AppRoutes.routes,
          ),
        ),
      );

      // 1. Start Assessment Screen
      expect(find.text('New Assessment'), findsOneWidget);
      expect(find.text('Soma (Reading)'), findsOneWidget);

      // Tap Soma (Reading)
      await tester.tap(find.text('Soma (Reading)'));
      await tester.pumpAndSettle();

      // 2. Select Learners Screen (Step 1 of 6)
      expect(find.text('Select learners'), findsOneWidget);
      expect(find.text('1 OF 6'), findsOneWidget);
      expect(find.text('Choose a small group for this session.'), findsOneWidget);

      // Select learners
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.textContaining('Continue with'));
      await tester.pumpAndSettle();

      // 3. Prepare Reading Screen (Step 2 of 6)
      expect(find.text('Prepare reading'), findsOneWidget);
      expect(find.text('2 OF 6'), findsOneWidget);
      expect(find.text('ENGLISH PASSAGE (LEVEL 2)'), findsOneWidget);
      expect(find.text('Start reading check'), findsOneWidget);

      // Tap Start Reading Check
      await tester.tap(find.text('Start reading check'));
      await tester.pumpAndSettle();

      // 4. Reading Check Screen (Step 3 of 6)
      expect(find.text('3 OF 6'), findsOneWidget);
      expect(find.text('TIMER RUNNING'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      // Pause the timer
      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(find.text('TIMER PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      // Resume timer
      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(find.text('TIMER RUNNING'), findsOneWidget);

      // Tap a word to mark mistake
      final wordToTap = find.text('walks');
      if (wordToTap.evaluate().isNotEmpty) {
        await tester.tap(wordToTap);
        await tester.pump();
      }

      // Finish & review
      await tester.tap(find.textContaining('review'));
      await tester.pumpAndSettle();

      // 5. Review & Rubric Selector Screen (Step 4 of 6)
      expect(find.textContaining('Reading review'), findsOneWidget);
      expect(find.text('SELECT A RESPONSE LEVEL'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Proficient'), 100);
      expect(find.text('Struggling'), findsOneWidget);
      expect(find.text('Developing'), findsOneWidget);
      expect(find.text('Proficient'), findsOneWidget);

      // Select Proficient (Level 3)
      await tester.tap(find.text('Proficient'));
      await tester.pumpAndSettle();

      // Finish or next student button is present
      expect(find.textContaining('learner'), findsWidgets);
    });
  });
}
