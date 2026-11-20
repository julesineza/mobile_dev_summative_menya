// OWNER: Member 1.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/view_state.dart';
import '../models/school_class.dart';
import '../services/school_class_service.dart';
import 'settings_provider.dart';

/// The signed-in teacher's classes (full CRUD) and which one is selected.
/// The selected class is saved in SharedPreferences through [SettingsProvider].
class ClassProvider extends ChangeNotifier {
  ClassProvider(this._service);

  final SchoolClassService _service;
  StreamSubscription<List<SchoolClass>>? _sub;
  SettingsProvider? _settings;
  String? _uid;

  ViewState state = ViewState.idle;
  List<SchoolClass> classes = const [];
  String? errorMessage;

  /// The class chosen by the teacher, or the first one if none / deleted.
  SchoolClass? get selectedClass {
    if (classes.isEmpty) return null;
    final id = _settings?.selectedClassId;
    for (final c in classes) {
      if (c.id == id) return c;
    }
    return classes.first;
  }

  /// Called by ProxyProvider whenever the user or settings change.
  /// Must not notify synchronously (it runs during the widget build).
  void configure({required String? uid, required SettingsProvider settings}) {
    _settings = settings;
    if (uid == _uid) return;

    _uid = uid;
    _sub?.cancel();
    _sub = null;
    classes = const [];
    errorMessage = null;

    if (uid == null) {
      state = ViewState.idle;
      return;
    }
    state = ViewState.loading;
    _sub = _service
        .watchMyClasses(uid)
        .listen(
          (list) {
            classes = list;
            state = ViewState.success;
            notifyListeners();
          },
          onError: (_) {
            state = ViewState.error;
            errorMessage = 'Could not load your classes.';
            notifyListeners();
          },
        );
  }

  Future<void> select(String classId) async {
    await _settings?.setSelectedClassId(classId);
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
      return true;
    } on Failure catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return false;
  }

  /// Creates a class, or updates it when [existing] is given.
  Future<bool> saveClass({
    SchoolClass? existing,
    required String schoolId,
    required String name,
    required int grade,
    String? academicYear,
  }) {
    final uid = _uid;
    if (uid == null) return Future.value(false);
    final schoolClass = SchoolClass(
      id: existing?.id ?? '',
      schoolId: schoolId,
      teacherId: uid,
      name: name,
      grade: grade,
      academicYear: academicYear,
    );
    return _run(
      () => existing == null
          ? _service.createClass(schoolClass)
          : _service.updateClass(schoolClass),
    );
  }

  Future<bool> deleteClass(SchoolClass schoolClass) =>
      _run(() => _service.deleteClass(schoolClass));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
