import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/failure.dart';
import 'package:mobile_dev_summative_menya/core/support_options.dart';
import 'package:mobile_dev_summative_menya/core/view_state.dart';
import 'package:mobile_dev_summative_menya/models/assessment_result.dart';
import 'package:mobile_dev_summative_menya/models/club_enrollment.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/remedial_club.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/models/support_plan.dart';
import 'package:mobile_dev_summative_menya/providers/review_provider.dart';
import 'package:mobile_dev_summative_menya/services/club_service.dart';
import 'package:mobile_dev_summative_menya/services/support_plan_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanService extends Mock implements SupportPlanService {}

class MockClubService extends Mock implements ClubService {}

const student = Student(
  id: 's1',
  schoolId: 'sch1',
  classId: 'c1',
  name: 'Bruno Niyonsaba',
  rollNo: 14,
);

final result = AssessmentResult(
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

final club = const RemedialClub(
  id: 'club1',
  schoolId: 'sch1',
  createdBy: 't1',
  name: 'Reading Club',
  subject: Subject.reading,
);

SupportPlan planFor(String id, {PlanStatus status = PlanStatus.active}) =>
    SupportPlan(
      id: id,
      schoolId: 'sch1',
      classId: 'c1',
      studentId: 's1',
      resultId: 'r1',
      teacherId: 't1',
      focus: 'Practise the marked word',
      practiceType: SupportActivity.pairedReading.storageName,
      createdAt: DateTime(2026, 9, 23),
      status: status,
    );

void main() {
  late MockPlanService service;
  late MockClubService clubs;
  late ReviewProvider provider;

  setUpAll(() {
    registerFallbackValue(ResponseLevel.struggling);
    registerFallbackValue(PlanStatus.active);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    service = MockPlanService();
    clubs = MockClubService();
    provider = ReviewProvider(service, clubs);

    when(() => service.getResult('r1')).thenAnswer((_) async => result);
    when(() => service.getStudent('s1')).thenAnswer((_) async => student);
    when(() => service.getResultsForStudent('s1', schoolId: 'sch1'))
        .thenAnswer((_) async => [result]);
    when(() => service.getPlansForStudent('s1', schoolId: 'sch1'))
        .thenAnswer((_) async => []);
    when(() => clubs.getClubs('sch1')).thenAnswer((_) async => [club]);
  });

  test('loadResult fills result, learner, level and clubs', () async {
    final ok = await provider.loadResult('r1');

    expect(ok, isTrue);
    expect(provider.state, ViewState.success);
    expect(provider.student, student);
    expect(provider.level, ResponseLevel.struggling);
    expect(provider.clubsForResult, [club]);
  });

  test('loadResult reports an error when the result is missing', () async {
    when(() => service.getResult('nope')).thenAnswer((_) async => null);

    final ok = await provider.loadResult('nope');

    expect(ok, isFalse);
    expect(provider.state, ViewState.error);
    expect(provider.error, 'This result could not be found.');
  });

  test('loadStudent falls back to the latest result', () async {
    await provider.loadStudent('s1');

    expect(provider.result?.id, 'r1');
  });

  test('saveReview sends the chosen level and note', () async {
    when(
      () => service.updateResultReview(
        resultId: any(named: 'resultId'),
        studentId: any(named: 'studentId'),
        level: any(named: 'level'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async {});
    await provider.loadResult('r1');

    provider.setLevel(ResponseLevel.developing);
    provider.setReviewNotes('Needs another try');
    final ok = await provider.saveReview();

    expect(ok, isTrue);
    verify(
      () => service.updateResultReview(
        resultId: 'r1',
        studentId: 's1',
        level: ResponseLevel.developing,
        notes: 'Needs another try',
      ),
    ).called(1);
  });

  group('savePlan', () {
    test('fails with a message when no activity is chosen', () async {
      await provider.loadResult('r1');

      final ok = await provider.savePlan(teacherId: 't1');

      expect(ok, isFalse);
      expect(provider.error, 'Choose a support activity first.');
    });

    test('uses the default focus and enrolls in the chosen club', () async {
      when(
        () => service.createPlan(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          studentId: any(named: 'studentId'),
          resultId: any(named: 'resultId'),
          teacherId: any(named: 'teacherId'),
          focus: any(named: 'focus'),
          practiceType: any(named: 'practiceType'),
          recheckDate: any(named: 'recheckDate'),
        ),
      ).thenAnswer((_) async => planFor('p1'));
      when(
        () => clubs.enrollStudent(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          clubId: any(named: 'clubId'),
          studentId: any(named: 'studentId'),
          enrolledBy: any(named: 'enrolledBy'),
          resultId: any(named: 'resultId'),
        ),
      ).thenAnswer(
        (_) async => ClubEnrollment(
          id: 'e1',
          schoolId: 'sch1',
          classId: 'c1',
          clubId: 'club1',
          studentId: 's1',
          enrolledBy: 't1',
          enrolledAt: DateTime(2026, 9, 23),
        ),
      );
      await provider.loadResult('r1');
      provider.selectActivity(SupportActivity.wordPractice);
      provider.selectClub(club);
      provider.useOneWeek(now: DateTime(2026, 9, 23));

      final ok = await provider.savePlan(teacherId: 't1');

      expect(ok, isTrue);
      expect(provider.savedPlan?.id, 'p1');
      expect(provider.plans.map((p) => p.id), ['p1']);
      verify(
        () => service.createPlan(
          schoolId: 'sch1',
          classId: 'c1',
          studentId: 's1',
          resultId: 'r1',
          teacherId: 't1',
          focus: defaultSupportFocus,
          practiceType: 'word practice',
          recheckDate: DateTime(2026, 9, 30),
        ),
      ).called(1);
      verify(
        () => clubs.enrollStudent(
          schoolId: 'sch1',
          classId: 'c1',
          clubId: 'club1',
          studentId: 's1',
          enrolledBy: 't1',
          resultId: 'r1',
        ),
      ).called(1);
    });

    test('shows the service message when saving fails', () async {
      when(
        () => service.createPlan(
          schoolId: any(named: 'schoolId'),
          classId: any(named: 'classId'),
          studentId: any(named: 'studentId'),
          resultId: any(named: 'resultId'),
          teacherId: any(named: 'teacherId'),
          focus: any(named: 'focus'),
          practiceType: any(named: 'practiceType'),
          recheckDate: any(named: 'recheckDate'),
        ),
      ).thenThrow(const Failure('Could not save the support plan.'));
      await provider.loadResult('r1');
      provider.selectActivity(SupportActivity.pairedReading);

      final ok = await provider.savePlan(teacherId: 't1');

      expect(ok, isFalse);
      expect(provider.state, ViewState.error);
      expect(provider.error, 'Could not save the support plan.');
    });
  });

  group('plan actions', () {
    setUp(() {
      when(() => service.getPlansForStudent('s1', schoolId: 'sch1'))
          .thenAnswer((_) async => [planFor('p1')]);
    });

    test('markRechecked updates the status in the list', () async {
      when(() => service.setPlanStatus('p1', PlanStatus.rechecked))
          .thenAnswer((_) async {});
      await provider.loadStudent('s1');

      await provider.markRechecked(provider.plans.first);

      expect(provider.plans.first.status, PlanStatus.rechecked);
    });

    test('scheduleRecheck sets the new date', () async {
      when(() => service.scheduleRecheck('p1', DateTime(2026, 10, 5)))
          .thenAnswer((_) async {});
      await provider.loadStudent('s1');

      await provider.scheduleRecheck(
        provider.plans.first,
        DateTime(2026, 10, 5),
      );

      expect(provider.plans.first.recheckDate, DateTime(2026, 10, 5));
    });

    test('deletePlan removes it from the list', () async {
      when(() => service.deletePlan('p1')).thenAnswer((_) async {});
      await provider.loadStudent('s1');

      await provider.deletePlan(provider.plans.first);

      expect(provider.plans, isEmpty);
      expect(provider.planForResult('r1'), isNull);
    });
  });
}
