import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'core/constants/app_theme.dart';
import 'screens/assessment/start_assessment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menya',
      theme: AppTheme.light,
      initialRoute: AppRoutes.start_assessment,
      routes: AppRoutes.routes,
    );
  }
}
