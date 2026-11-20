// OWNER: Member 1.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/view_state.dart';
import '../models/assessment_session.dart';
import '../models/enums.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../services/dashboard_service.dart';

/// Counts shown in the "class overview" cards.
class DashboardSummary {
  const DashboardSummary({
    this.total = 0,
    this.onTrack = 0,
    this.watch = 0,
    this.needsSupport = 0,
  });

  factory DashboardSummary.fromStudents(List<Student> students) {
    int count(SupportStatus status) =>
        students.where((s) => s.status == status).length;
    return DashboardSummary(
      total: students.length,
      onTrack: count(SupportStatus.onTrack),
      watch: count(SupportStatus.watch),
      needsSupport: count(SupportStatus.needsSupport),
    );
  }

  final int total;
  final int onTrack;
  final int watch;
  final int needsSupport;
}

/// Live dashboard data for the selected class: student counts by status and
/// the most recent quick checks.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._service);

  final DashboardService _service;
  StreamSubscription<List<Student>>? _studentsSub;
  StreamSubscription<List<AssessmentSession>>? _sessionsSub;
  String? _classId;

  ViewState summaryState = ViewState.idle;
  ViewState recentState = ViewState.idle;
  DashboardSummary summary = const DashboardSummary();
  List<AssessmentSession> recentChecks = const [];

  /// Called by ProxyProvider whenever the selected class changes.
  /// Must not notify synchronously (it runs during the widget build).
  void watchClass(SchoolClass? schoolClass) {
    if (schoolClass?.id == _classId) return;
    _classId = schoolClass?.id;

    _studentsSub?.cancel();
    _sessionsSub?.cancel();
    summary = const DashboardSummary();
    recentChecks = const [];

    if (schoolClass == null) {
      summaryState = ViewState.idle;
      recentState = ViewState.idle;
      return;
    }
    summaryState = ViewState.loading;
    recentState = ViewState.loading;

    _studentsSub = _service
        .watchStudents(schoolClass)
        .listen(
          (students) {
            summary = DashboardSummary.fromStudents(students);
            summaryState = ViewState.success;
            notifyListeners();
          },
          onError: (_) {
            summaryState = ViewState.error;
            notifyListeners();
          },
        );
    _sessionsSub = _service
        .watchRecentSessions(schoolClass)
        .listen(
          (sessions) {
            recentChecks = sessions;
            recentState = ViewState.success;
            notifyListeners();
          },
          onError: (_) {
            recentState = ViewState.error;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    _sessionsSub?.cancel();
    super.dispose();
  }
}
