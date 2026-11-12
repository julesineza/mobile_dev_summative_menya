import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';

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
    Grade(level: 'P1 A', classSize: '50'),
    Grade(level: 'P1 B', classSize: '40'),
    Grade(level: 'P2 A', classSize: '40'),
    Grade(level: 'P2 B', classSize: '56'),
  ];

  int get selectedCount => classes.where((e) => e.isSelected).length;
  bool get allSelected => classes.isNotEmpty && selectedCount == classes.length;

  void toggleAll() {
    setState(() {
      final newValue = !allSelected;
      for (var c in classes) {
        c.isSelected = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    const lightGreen = Color(0xFFD9EADF);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    '1 OF 6',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                children: [
                  const Text(
                    'Select Class',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Choose a class for this session.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${classes.length} CLASSES',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      GestureDetector(
                        onTap: toggleAll,
                        child: Text(
                          allSelected ? 'Deselect all' : 'Select all',
                          style: const TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Class cards
                  ...classes.map((grade) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => grade.isSelected = !grade.isSelected);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: grade.isSelected
                                  ? green
                                  : const Color(0xFFE8DDC8),
                              width: grade.isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: lightGreen,
                                child: Text(
                                  grade.level, // FIXED: was Grade.level
                                  style: const TextStyle(
                                    color: green,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class ${grade.level}', // FIXED: was learner.name
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${grade.classSize} learners', // FIXED: was learner.className
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Custom checkbox
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: grade.isSelected
                                      ? green
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: grade.isSelected
                                        ? green
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: grade.isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 60),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'You can select multiple classes or just one for this session.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          final selected = classes
                              .where((e) => e.isSelected)
                              .toList();
                          Navigator.of(context)
                              .pushNamed(AppRoutes.selectLearners);
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
                    selectedCount == 0
                        ? 'Select a class to continue'
                        : 'Continue with $selectedCount ${selectedCount == 1 ? 'class' : 'classes'}',
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
