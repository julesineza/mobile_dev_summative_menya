import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/view_state.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../services/student_service.dart';

enum RosterFilter { all, needsSupport, watch }

class StudentProvider extends ChangeNotifier {
  StudentProvider(this._service);
  final StudentService _service;
  StreamSubscription<List<Student>>? _sub;

  ViewState state = ViewState.idle;
  String? error;
  String? classId;
  String className = '';

  List<Student> _students = [];
  String _query = '';
  RosterFilter filter = RosterFilter.all;

  List<Student> get all => _students;
  int get total => _students.length;
  int countOf(SupportStatus s) => _students.where((x) => x.status == s).length;

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

  void listenToClass(String classId, {String className = ''}) {
    this.className = className;
    if (this.classId == classId && _sub != null) return;
    this.classId = classId;
    _sub?.cancel();
    _students = [];
    state = ViewState.loading;
    // no notifyListeners() here: the proxy provider rebuilds the screens itself
    _sub = _service
        .streamStudents(classId)
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
    super.dispose();
  }
}
