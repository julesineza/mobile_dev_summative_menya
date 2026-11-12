/// All route paths in one place (lib/app_routes.dart). Add yours via PR.

import 'package:flutter/material.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/assessment_reading.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/prepare_reading.dart';
import '/screens/assessment/start_assessment.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/assessment_math.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/select_learners.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/select_class.dart';
import 'package:mobile_dev_summative_menya/screens/assessment/take_reading.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const students = '/students';
  static const studentProfile = '/students/:id';
  static const start_assessment = '/assess';
  static const assessReading = '/assess/reading';
  static const assessMath = '/assess/math';
  static const prepareReading = '/assess/reading/prepare';
  static const takeReading = '/assess/reading/take';
  static const selectLearners = '/assess/select-learners';
  static const selectClass = '/assess/select-class';
  static const progress = '/progress';
  static const review = '/review/:resultId';
  static const supportPlan = '/support-plan/:studentId';

  static final Map<String, WidgetBuilder> routes = {
    start_assessment: (context) => const StartAssessment(),
    assessReading: (context) => const AssessmentReading(),
    assessMath: (context) => const AssessmentMath(),
    prepareReading: (context) => const PrepareReadingPage(),
    takeReading: (context) => const ReadingPausedPage(),
    selectLearners: (context) => const SelectLearnersPage(),
    selectClass: (context) => const SelectClassesPage(),
  };
}
