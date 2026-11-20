// OWNER: Member 1.
import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/view_state.dart';
import '../models/school.dart';
import '../services/school_class_service.dart';

/// The list of schools for the registration dropdown.
class SchoolProvider extends ChangeNotifier {
  SchoolProvider(this._service);

  final SchoolClassService _service;

  ViewState state = ViewState.idle;
  List<School> schools = const [];
  String? errorMessage;

  String nameFor(String id) {
    for (final school in schools) {
      if (school.id == id) return school.name;
    }
    return '';
  }

  /// Safe to call from initState: it only notifies after the first await.
  Future<void> load({bool force = false}) async {
    if (state == ViewState.loading) return;
    if (state == ViewState.success && !force) return;

    state = ViewState.loading;
    errorMessage = null;
    try {
      schools = await _service.getSchools();
      state = ViewState.success;
    } on Failure catch (e) {
      state = ViewState.error;
      errorMessage = e.message;
    } catch (_) {
      state = ViewState.error;
      errorMessage = 'Could not load schools.';
    }
    notifyListeners();
  }
}
