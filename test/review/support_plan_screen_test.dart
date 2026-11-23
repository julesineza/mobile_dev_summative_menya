import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/support_options.dart';
import 'package:mobile_dev_summative_menya/models/assessment_result.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/providers/review_provider.dart';
import 'package:mobile_dev_summative_menya/screens/review/review_result_screen.dart';
import 'package:mobile_dev_summative_menya/screens/review/support_plan_screen.dart';
import 'package:mobile_dev_summative_menya/services/club_service.dart';
import 'package:mobile_dev_summative_menya/services/support_plan_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockPlanService extends Mock implements SupportPlanService {}

class MockClubService extends Mock implements ClubService {}

const _student = Student(
  id: 's1',
  schoolId: 'sch1',
  classId: 'c1',
  name: 'Bruno Niyonsaba',
  rollNo: 14,
);

final _result = AssessmentResult(
  id: 'r1',
  schoolId: 'sch1',
  classId: 'c1',
  sessionId: 'a1',
  studentId: 's1',
  teacherId: 't1',
  subject: Subject.reading,
  level: ResponseLevel.struggling,
  durationSec: 30,
  createdAt: DateTime(2026, 9, 23),
  wordsPerMinute: 38,
  accuracy: 95,
);

void main() {
  late ReviewProvider provider;

  setUp(() {
    final service = MockPlanService();
    final clubs = MockClubService();
    when(() => service.getResult('r1')).thenAnswer((_) async => _result);
    when(() => service.getStudent('s1')).thenAnswer((_) async => _student);
    when(() => service.getResultsForStudent('s1', schoolId: 'sch1'))
        .thenAnswer((_) async => [_result]);
    when(() => service.getPlansForStudent('s1', schoolId: 'sch1'))
        .thenAnswer((_) async => []);
    when(() => clubs.getClubs('sch1')).thenAnswer((_) async => []);
    provider = ReviewProvider(service, clubs);
  });

  Widget wrap(Widget child) => ChangeNotifierProvider<ReviewProvider>.value(
    value: provider,
    child: MaterialApp(home: child),
  );

  testWidgets('support plan: recheck button needs an activity first', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SupportPlanScreen(studentId: 's1')));
    await tester.pumpAndSettle();

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Choose a recheck date'),
    );
    expect(find.text('Bruno Niyonsaba'), findsOneWidget);
    expect(button().onPressed, isNull);

    await tester.tap(find.byKey(const Key('activity_wordPractice')));
    await tester.pumpAndSettle();

    expect(provider.activity, SupportActivity.wordPractice);
    expect(button().onPressed, isNotNull);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
  });

  testWidgets(
    'review: shows words per minute and lets the teacher pick a level',
    (tester) async {
      await tester.pumpWidget(wrap(const ReviewResultScreen(resultId: 'r1')));
      await tester.pumpAndSettle();

      expect(find.text('38'), findsOneWidget);
      expect(find.text('Confirm & save result'), findsOneWidget);

      await tester.ensureVisible(find.text('Proficient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proficient'));
      await tester.pumpAndSettle();

      expect(provider.level, ResponseLevel.proficient);
    },
  );
}
