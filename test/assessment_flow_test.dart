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
      expect(Grading.levelFromPercent(85.0), ResponseLevel.proficient);
      expect(Grading.levelFromPercent(84.9), ResponseLevel.developing);
      expect(Grading.levelFromPercent(60.0), ResponseLevel.developing);
      expect(Grading.levelFromPercent(59.9), ResponseLevel.struggling);
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

    testWidgets('Set up custom test flows for Reading and Math', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // Verify custom test setup card is visible on StartAssessment
      expect(find.text('Set up a custom test'), findsOneWidget);
      await tester.tap(find.text('Set up'));
      await tester.pumpAndSettle();

      // Verify on Reading setup page
      expect(find.text('Set up a test'), findsOneWidget);
      expect(find.text('Soma · Reading'), findsOneWidget);
      expect(find.text('Imibare · Math'), findsOneWidget);
      expect(find.text('Reading content'), findsOneWidget);

      // Switch to Math setup page
      await tester.tap(find.text('Imibare · Math'));
      await tester.pumpAndSettle();

      // Verify on Math setup page
      expect(find.text('Math questions'), findsOneWidget);
      expect(find.text('Add question'), findsOneWidget);

      // Add a question
      await tester.tap(find.text('Add question'));
      await tester.pump();
      expect(find.text('4 questions'), findsOneWidget);

      // Switch back to Reading setup page
      await tester.tap(find.text('Soma · Reading'));
      await tester.pumpAndSettle();
      expect(find.text('Reading content'), findsOneWidget);
    });

    testWidgets('Change class flow redirects back to choose assessment page',
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

      // Initially active class is P3-A
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('P3-A'),
        ),
        findsOneWidget,
      );
      expect(find.text('Change'), findsOneWidget);

      // Tap Change class
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      // Verify on Select Class page
      expect(find.text('Select Class'), findsOneWidget);
      expect(find.text('Class P1-B'), findsOneWidget);

      // Select P1-B
      await tester.tap(find.text('Class P1-B'));
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.text('Set P1-B as active class'));
      await tester.pumpAndSettle();

      // Verify redirected back to StartAssessment (Choose assessment page)
      expect(find.text('New Assessment'), findsOneWidget);
      expect(provider.selectedClassName, 'P1-B');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Class P1-B is active'),
        ),
        findsOneWidget,
      );
      expect(find.text('Soma (Reading)'), findsOneWidget);
      expect(find.text('Imibare (Mathematics)'), findsOneWidget);
    });
  });
}
