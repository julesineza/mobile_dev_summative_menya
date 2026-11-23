// OWNER: Member 2.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/failure.dart';
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

  /// Set when the server rejects an add/delete that already showed as done.
  String? syncError;

  /// Set when assessment results can't load (the roster still works).
  String? resultsError;
  bool _disposed = false;
  String? classId;
  String className = '';

  List<Student> _students = [];
  List<AssessmentResult> _results = [];

  String _query = '';
  RosterFilter filter = RosterFilter.all;

  List<Student> get all => _students;
  List<Student> get students => _students;
  int get total => _students.length;
  bool get isLoading => state == ViewState.loading;
  String? get errorMessage => error;
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
        .listen(
          (list) {
            _results = list;
            resultsError = null;
            notifyListeners();
          },
          onError: (Object e) {
            // The roster still works; just say the results are missing.
            debugPrint('[StudentProvider] results stream failed: $e');
            resultsError = 'Could not load assessment results.';
            notifyListeners();
          },
        );
    _sub = _service
        .streamStudents(classId, schoolId: schoolId)
        .listen(
          (list) {
            _students = list;
            state = ViewState.success;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('[StudentProvider] students stream failed: $e');
            state = ViewState.error;
            error = 'Could not load students. Check your connection.';
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

  /// Starts (or restarts) listening to the students of [classId].
  /// Pass null to stop listening.
  void watchClass(String? classId) {
    if (classId == null) {
      _sub?.cancel();
      _resultsSub?.cancel();
      _sub = null;
      _resultsSub = null;
      this.classId = null;
      _students = [];
      _results = [];
      state = ViewState.idle;
      error = null;
      notifyListeners();
      return;
    }
    listenToClass(classId);
  }

  Future<bool> _run(Future<void> Function() action) async {
    error = null;
    try {
      await action();
      return true;
    } on Failure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return false;
  }

  /// Adds a student to the Firestore `students` collection.
  /// [id] is left empty so Firestore generates the document id.
  Future<bool> addStudent({
    required String schoolId,
    required String classId,
    required String name,
    required int rollNo,
  }) => _run(
    () => _service.addStudent(
      Student(
        id: '',
        schoolId: schoolId,
        classId: classId,
        name: name,
        rollNo: rollNo,
        status: SupportStatus.onTrack,
      ),
      onError: (f) => _reportSyncError('Could not add $name. ${f.message}'),
    ),
  );

  Future<bool> deleteStudent(String studentId) {
    final name = byId(studentId)?.name ?? 'the student';
    return _run(
      () => _service.deleteStudent(
        studentId,
        onError: (f) =>
            _reportSyncError('Could not remove $name. ${f.message}'),
      ),
    );
  }

  /// Called later, when the server rejects a write the UI already accepted.
  void _reportSyncError(String message) {
    if (_disposed) return;
    syncError = message;
    notifyListeners();
  }

  void clearSyncError() {
    syncError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _resultsSub?.cancel();
    super.dispose();
  }
}
