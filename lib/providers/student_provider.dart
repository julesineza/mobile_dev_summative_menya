// OWNER: Member 2.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../services/student_service.dart';

/// Students of the currently selected class, streamed live from Firestore.
class StudentProvider extends ChangeNotifier {
  StudentProvider(this._service);

  final StudentService _service;
  StreamSubscription<List<Student>>? _sub;

  String? _classId;
  List<Student> students = const [];
  String? errorMessage;
  bool isLoading = false;

  /// Starts (or restarts) listening to the students of [classId].
  /// Pass null to stop listening.
  void watchClass(String? classId) {
    if (classId == _classId && _sub != null) return;
    _classId = classId;
    _sub?.cancel();
    _sub = null;
    students = const [];
    errorMessage = null;

    if (classId == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    _sub = _service
        .watchStudents(classId)
        .listen(
          (list) {
            students = list;
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (_) {
            isLoading = false;
            errorMessage = 'Could not load students.';
            notifyListeners();
          },
        );
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
    ),
  );

  Future<bool> deleteStudent(String studentId) =>
      _run(() => _service.deleteStudent(studentId));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
