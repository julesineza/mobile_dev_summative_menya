import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/settings_provider.dart';

class Grade {
  final String level;
  final String classSize;
  bool isSelected;

  Grade({
    required this.level,
    required this.classSize,
    this.isSelected = false,
  });
}

class SelectClassesPage extends StatefulWidget {
  const SelectClassesPage({super.key});

  @override
  State<SelectClassesPage> createState() => _SelectClassesPageState();
}

class _SelectClassesPageState extends State<SelectClassesPage> {
  final List<Grade> classes = [
    Grade(level: 'P1-A', classSize: '50'),
    Grade(level: 'P1-B', classSize: '40'),
    Grade(level: 'P2-A', classSize: '40'),
    Grade(level: 'P2-B', classSize: '56'),
    Grade(level: 'P3-A', classSize: '45'),
    Grade(level: 'P3-B', classSize: '42'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = context.read<AssessmentProvider>().selectedClassName;
      setState(() {
        for (var c in classes) {
          c.isSelected = (c.level == current ||
              c.level.replaceAll('-', ' ') == current ||
              c.level == current.replaceAll(' ', '-'));
        }
        if (!classes.any((c) => c.isSelected)) {
          classes
              .firstWhere((c) => c.level == 'P3-A', orElse: () => classes.first)
              .isSelected = true;
        }
      });
    });
  }

  Grade? get selectedGrade =>
      classes.where((e) => e.isSelected).firstOrNull;

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    const lightGreen = AppColors.primarySoft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left, color: green, size: 20),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'CHANGE CLASS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  const Text(
                    'Select Class',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the active class to assess or configure tests for.',
                    style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 20),

                  // Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${classes.length} AVAILABLE CLASSES',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (selectedGrade != null)
                        Text(
                          'Selected: ${selectedGrade!.level}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: green,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Class cards
                  ...classes.map((grade) {
                    final isSelected = grade.isSelected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            for (var c in classes) {
                              c.isSelected = (c == grade);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? green : AppColors.border,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isSelected ? green : lightGreen,
                                child: Text(
                                  grade.level,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : green,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class ${grade.level}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${grade.classSize} registered learners',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Radio-style selection circle
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? green : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? green : Colors.grey.shade400,
                                    width: 1.8,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Selecting a class sets it active for quick checks, math tests, and reading sessions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Confirm Button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: selectedGrade == null
                      ? null
                      : () {
                          final selected = selectedGrade!;
                          final formattedName = selected.level.replaceAll(' ', '-');
                          // Update AssessmentProvider (session-scoped).
                          context.read<AssessmentProvider>().setSelectedClass(
                                name: formattedName,
                                id: 'class-${formattedName.toLowerCase()}',
                              );
                          // Persist to SharedPreferences via SettingsProvider (survives app restart).
                          context.read<SettingsProvider>().setActiveClass(formattedName);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Active class changed to $formattedName'),
                              backgroundColor: AppColors.button,
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          // Redirect to Choose Assessment page (StartAssessment)
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacementNamed(
                              AppRoutes.start_assessment,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    disabledBackgroundColor: green.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    selectedGrade == null
                        ? 'Select a class'
                        : 'Set ${selectedGrade!.level} as active class',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
