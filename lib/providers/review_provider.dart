// owner: member 4. state for the review, support plan and history flow.
import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/support_options.dart';
import '../core/view_state.dart';
import '../models/assessment_result.dart';
import '../models/enums.dart';
import '../models/remedial_club.dart';
import '../models/student.dart';
import '../models/support_plan.dart';
import '../services/club_service.dart';
import '../services/support_plan_service.dart';

/// keeps the loaded learner, result and plan draft across the flow screens.
class ReviewProvider extends ChangeNotifier {
  ReviewProvider(this._service, this._clubs);

  final SupportPlanService _service;
  final ClubService _clubs;

  ViewState state = ViewState.idle;
  String? error;

  Student? student;
  AssessmentResult? result;
  List<AssessmentResult> results = [];
  List<SupportPlan> plans = [];
  List<RemedialClub> clubs = [];

  ResponseLevel? level;
  String reviewNotes = '';

  SupportActivity? activity;
  String planNote = '';
  DateTime? recheckDate;
  RemedialClub? selectedClub;
  SupportPlan? savedPlan;

  bool get isLoading => state == ViewState.loading;
  bool get canChooseRecheck => activity != null;

  /// plan created for the given result, if any.
  SupportPlan? planForResult(String resultId) {
    for (final p in plans) {
      if (p.resultId == resultId) return p;
    }
    return null;
  }

  /// only clubs matching the result's subject are offered.
  List<RemedialClub> get clubsForResult => result == null
      ? clubs
      : clubs.where((c) => c.subject == result!.subject).toList();

  /// loads one saved result and its learner.
  Future<bool> loadResult(String resultId) => _run(() async {
    _resetDrafts();
    final r = await _service.getResult(resultId);
    if (r == null) throw const Failure('This result could not be found.');
    result = r;
    level = r.level;
    reviewNotes = r.notes ?? '';
    student = await _service.getStudent(r.studentId);
    await _loadStudentData(r.studentId, r.schoolId);
  });

  /// loads a learner and a result, using the latest result when [resultId] is null.
  Future<bool> loadStudent(String studentId, {String? resultId}) =>
      _run(() async {
        _resetDrafts();
        final s = await _service.getStudent(studentId);
        if (s == null) throw const Failure('This learner could not be found.');
        student = s;
        await _loadStudentData(studentId, s.schoolId);
        result = _pickResult(resultId);
        level = result?.level;
        reviewNotes = result?.notes ?? '';
      });

  Future<void> _loadStudentData(String studentId, String schoolId) async {
    results = await _service.getResultsForStudent(
      studentId,
      schoolId: schoolId,
    );
    plans = await _service.getPlansForStudent(studentId, schoolId: schoolId);
    clubs = await _clubs.getClubs(schoolId);
  }

  AssessmentResult? _pickResult(String? resultId) {
    if (results.isEmpty) return null;
    if (resultId != null) {
      for (final r in results) {
        if (r.id == resultId) return r;
      }
    }
    return results.first;
  }

  void _resetDrafts() {
    activity = null;
    planNote = '';
    recheckDate = null;
    selectedClub = null;
    savedPlan = null;
  }

  void setLevel(ResponseLevel value) {
    level = value;
    notifyListeners();
  }

  void setReviewNotes(String value) => reviewNotes = value;

  /// saves the final level and note, returns false on failure.
  Future<bool> saveReview() async {
    final r = result;
    final l = level;
    if (r == null || l == null) return false;
    return _run(() async {
      await _service.updateResultReview(
        resultId: r.id,
        studentId: r.studentId,
        level: l,
        notes: reviewNotes,
      );
      result = await _service.getResult(r.id) ?? r;
    });
  }

  void selectActivity(SupportActivity value) {
    activity = value;
    notifyListeners();
  }

  void setPlanNote(String value) => planNote = value;

  void setRecheckDate(DateTime? date) {
    recheckDate = date;
    notifyListeners();
  }

  void useOneWeek({DateTime? now}) =>
      setRecheckDate(oneWeekFrom(now ?? DateTime.now()));

  void selectClub(RemedialClub? club) {
    selectedClub = club;
    notifyListeners();
  }

  /// creates the plan and enrolls the learner if a club was chosen.
  Future<bool> savePlan({required String teacherId}) async {
    final s = student;
    final r = result;
    final a = activity;
    if (s == null || r == null || a == null) {
      error = 'Choose a support activity first.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      final note = planNote.trim();
      final plan = await _service.createPlan(
        schoolId: s.schoolId,
        classId: s.classId,
        studentId: s.id,
        resultId: r.id,
        teacherId: teacherId,
        focus: note.isEmpty ? defaultSupportFocus : note,
        practiceType: a.storageName,
        recheckDate: recheckDate,
      );
      savedPlan = plan;
      plans = [plan, ...plans];
      final club = selectedClub;
      if (club != null) {
        await _clubs.enrollStudent(
          schoolId: s.schoolId,
          classId: s.classId,
          clubId: club.id,
          studentId: s.id,
          enrolledBy: teacherId,
          resultId: r.id,
        );
      }
    });
  }

  Future<bool> createClub({
    required String name,
    required String teacherId,
    String? schedule,
  }) async {
    final s = student;
    final r = result;
    if (s == null || r == null || name.trim().isEmpty) return false;
    return _run(() async {
      final club = await _clubs.createClub(
        schoolId: s.schoolId,
        createdBy: teacherId,
        name: name,
        subject: r.subject,
        schedule: schedule,
      );
      clubs = [...clubs, club];
      selectedClub = club;
    });
  }

  Future<bool> markRechecked(SupportPlan plan) =>
      _setStatus(plan, PlanStatus.rechecked);

  Future<bool> closePlan(SupportPlan plan) =>
      _setStatus(plan, PlanStatus.closed);

  /// sets or changes the recheck date on a saved plan.
  Future<bool> scheduleRecheck(SupportPlan plan, DateTime date) =>
      _run(() async {
        await _service.scheduleRecheck(plan.id, date);
        plans = [
          for (final p in plans)
            p.id == plan.id ? _copy(p, recheckDate: date) : p,
        ];
      });

  SupportPlan _copy(
    SupportPlan p, {
    DateTime? recheckDate,
    PlanStatus? status,
  }) => SupportPlan(
    id: p.id,
    schoolId: p.schoolId,
    classId: p.classId,
    studentId: p.studentId,
    resultId: p.resultId,
    teacherId: p.teacherId,
    focus: p.focus,
    practiceType: p.practiceType,
    createdAt: p.createdAt,
    recheckDate: recheckDate ?? p.recheckDate,
    status: status ?? p.status,
  );

  Future<bool> _setStatus(SupportPlan plan, PlanStatus status) =>
      _run(() async {
        await _service.setPlanStatus(plan.id, status);
        plans = [
          for (final p in plans) p.id == plan.id ? _copy(p, status: status) : p,
        ];
      });

  Future<bool> deletePlan(SupportPlan plan) => _run(() async {
    await _service.deletePlan(plan.id);
    plans = plans.where((p) => p.id != plan.id).toList();
  });

  /// runs [action] with loading and error handling, true on success.
  Future<bool> _run(Future<void> Function() action) async {
    state = ViewState.loading;
    error = null;
    notifyListeners();
    try {
      await action();
      state = ViewState.success;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      state = ViewState.error;
      error = e.message;
    } catch (_) {
      state = ViewState.error;
      error = 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return false;
  }
}
