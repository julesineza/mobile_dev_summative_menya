import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/view_state.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../models/assessment_result.dart';
import '../services/student_service.dart';

enum RosterFilter { all, needsSupport, watch }

class StudentProvider extends ChangeNotifier {
  StudentProvider(this._service);
  final StudentService _service;
  StreamSubscription<List<Student>>? _sub;
  StreamSubscription<List<AssessmentResult>>? _resultsSub;

  ViewState state = ViewState.idle;
  String? error;
  String? classId;
  String className = '';

  List<Student> _students = [];
  List<AssessmentResult> _results = [];

  String _query = '';
  RosterFilter filter = RosterFilter.all;

  List<Student> get all => _students;
  int get total => _students.length;
  int countOf(SupportStatus s) => _students.where((x) => x.status == s).length;

  List<AssessmentResult> get results => _results;
  List<AssessmentResult> resultsFor(String studentId) =>
      _results.where((r) => r.studentId == studentId).toList();

  List<Student> get needsAttention =>
      _students.where((s) => s.status == SupportStatus.needsSupport).toList();

  List<Student> get visible {
    final q = _query.trim().toLowerCase();
    return _students.where((s) {
      final matchesFilter = switch (filter) {
        RosterFilter.all => true,
        RosterFilter.needsSupport => s.status == SupportStatus.needsSupport,
        RosterFilter.watch => s.status == SupportStatus.watch,
      };
      return matchesFilter && (q.isEmpty || s.name.toLowerCase().contains(q));
    }).toList();
  }

  Student? byId(String id) {
    for (final s in _students) {
      if (s.id == id) return s;
    }
    return null;
  }

  void listenToClass(
    String classId, {
    String? schoolId,
    String className = '',
  }) {
    this.className = className;
    if (this.classId == classId && _sub != null) return;
    this.classId = classId;
    _sub?.cancel();
    _resultsSub?.cancel();
    _students = [];
    _results = [];
    state = ViewState.loading;
    // no notifyListeners() the proxy provider rebuilds the screens itself
    _resultsSub = _service
        .streamClassResults(classId, schoolId: schoolId)
        .listen((list) {
          _results = list;
          notifyListeners();
        }, onError: (Object _) {}); // roster still works if results fail
    _sub = _service
        .streamStudents(classId, schoolId: schoolId)
        .listen(
          (list) {
            _students = list;
            state = ViewState.success;
            notifyListeners();
          },
          onError: (Object e) {
            state = ViewState.error;
            error = e.toString();
            notifyListeners();
          },
        );
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setFilter(RosterFilter f) {
    filter = f;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _resultsSub?.cancel();
    super.dispose();
  }
}
