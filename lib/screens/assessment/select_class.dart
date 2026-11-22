import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../models/school_class.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/settings_provider.dart';

class SelectClassesPage extends StatefulWidget {
  const SelectClassesPage({super.key});

  @override
  State<SelectClassesPage> createState() => _SelectClassesPageState();
}

class _SelectClassesPageState extends State<SelectClassesPage> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classProvider = context.read<ClassProvider>();
      setState(() {
        _selectedClassId = classProvider.selectedClass?.id;
      });
    });
  }

  SchoolClass? get selectedClass =>
      context.watch<ClassProvider>().classes.firstWhere(
        (c) => c.id == _selectedClassId,
        orElse: () => context.watch<ClassProvider>().classes.first,
      );

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
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section header
                  Consumer<ClassProvider>(
                    builder: (_, classProvider, __) {
                      final classes = classProvider.classes;
                      return Row(
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
                          if (_selectedClassId != null)
                            Text(
                              'Selected: ${classes.firstWhere((c) => c.id == _selectedClassId, orElse: () => classes.first).name}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: green,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Class cards
                  Consumer<ClassProvider>(
                    builder: (_, classProvider, __) {
                      final classes = classProvider.classes;
                      return Column(
                        children: classes.map((schoolClass) {
                          final isSelected = schoolClass.id == _selectedClassId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedClassId = schoolClass.id;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? green
                                        : AppColors.border,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isSelected
                                          ? green
                                          : lightGreen,
                                      child: Text(
                                        schoolClass.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : green,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Class ${schoolClass.name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Grade ${schoolClass.grade}',
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
                                        color: isSelected
                                            ? green
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? green
                                              : Colors.grey.shade400,
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
                        }).toList(),
                      );
                    },
                  ),

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
                child: Consumer<ClassProvider>(
                  builder: (_, classProvider, __) {
                    final selectedClass = classProvider.classes.firstWhere(
                      (c) => c.id == _selectedClassId,
                      orElse: () => classProvider.classes.first,
                    );
                    return ElevatedButton(
                      onPressed: _selectedClassId == null
                          ? null
                          : () {
                              final formattedName = selectedClass.name;
                              // Update AssessmentProvider (session-scoped).
                              context
                                  .read<AssessmentProvider>()
                                  .setSelectedClass(
                                    name: formattedName,
                                    id: selectedClass.id,
                                  );
                              // Update ClassProvider selection.
                              context.read<ClassProvider>().select(
                                selectedClass.id,
                              );
                              // Persist to SharedPreferences via SettingsProvider (survives app restart).
                              context.read<SettingsProvider>().setActiveClass(
                                formattedName,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Active class changed to $formattedName',
                                  ),
                                  backgroundColor: AppColors.button,
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              // Redirect to Choose Assessment page (StartAssessment)
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.assess);
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
                        _selectedClassId == null
                            ? 'Select a class'
                            : 'Set ${selectedClass.name} as active class',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
