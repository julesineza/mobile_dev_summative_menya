import 'package:flutter/material.dart';
import 'package:mobile_dev_summative_menya/app_routes.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';

class Learner {
  final String id;
  final String name;
  final String initials;
  final String className;
  bool isSelected;

  Learner({
    required this.id,
    required this.name,
    required this.initials,
    required this.className,
    this.isSelected = false,
  });
}

String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  
  if (parts.isEmpty || parts[0].isEmpty) return '';

  if (parts.length >= 2) {
    final firstInitial = parts.first[0];
    final lastInitial = parts.last[0];
    return '$firstInitial$lastInitial'.toUpperCase();
  } 
  
  final singleName = parts[0];
  return singleName.length >= 2 
      ? singleName.substring(0, 2).toUpperCase() 
      : singleName.toUpperCase();
}


class SelectLearnersPage extends StatefulWidget {
  const SelectLearnersPage({super.key});

  @override
  State<SelectLearnersPage> createState() => _SelectLearnersPageState();
}

class _SelectLearnersPageState extends State<SelectLearnersPage> {
  List<Learner> learners = [
    Learner(id: 'temporary-student-bruno', name: 'Bruno Niyonsaba', initials: getInitials('Bruno Niyonsaba'), className: 'Class P3-A'),
    Learner(id: 'temporary-student-fiona', name: 'Fiona Uwase', initials: getInitials('Fiona Uwase'), className: 'Class P3-A'),
    Learner(id: 'temporary-student-aliane', name: 'Aliane Umutoni', initials: getInitials('Aliane Umutoni'), className: 'Class P3-A'),
    Learner(id: 'temporary-student-cynthia', name: 'Cynthia Gisa', initials: getInitials('Cynthia Gisa'), className: 'Class P3-A'),
  ];

  @override
  void initState() {
    super.initState();
    _loadLearners();
  }

  Future<void> _loadLearners() async {
    final loaded = await context.read<AssessmentProvider>().loadLearners();
    if (!mounted || loaded.isEmpty) return;
    setState(() {
      learners = loaded
          .map(
            (learner) => Learner(
              id: learner.id,
              name: learner.name,
              initials: learner.initials,
              className: learner.className,
            ),
          )
          .toList();
    });
  }

  int get selectedCount => learners.where((e) => e.isSelected).length;
  bool get allSelected => selectedCount == learners.length;

  void toggleAll() {
    setState(() {
      final newValue = !allSelected;
      for (var l in learners) {
        l.isSelected = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    const lightGreen = Color(0xFFD9EADF);

    return Scaffold(
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
                    'Select learners',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Choose a small group for this session.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'P3-A • 6 SAMPLE LEARNERS',
                        style: TextStyle(
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

                  // Learner cards
                  ...learners.map((learner) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => learner.isSelected = !learner.isSelected);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: learner.isSelected ? green : const Color(0xFFE8DDC8),
                              width: learner.isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: lightGreen,
                                child: Text(
                                  learner.initials,
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
                                      learner.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      learner.className,
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
                                  color: learner.isSelected ? green : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: learner.isSelected ? green : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: learner.isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
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
                      'You can skip an absent learner or pause between checks.',
                      style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
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
                  onPressed: () async {
                    final selected = learners.where((e) => e.isSelected).toList();
                    if (selected.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select at least one learner.')),
                      );
                      return;
                    }

                    final provider = context.read<AssessmentProvider>();
                    provider.setLearners(
                      selected
                          .map(
                            (learner) => AssessmentLearner(
                              id: learner.id,
                              name: learner.name,
                              initials: learner.initials,
                              className: learner.className,
                              schoolId: AssessmentProvider.fallbackSchoolId,
                              classId: AssessmentProvider.fallbackClassId,
                            ),
                          )
                          .toList(),
                    );
                    await provider.prepareAssessment();

                    if (!mounted) return;
                    final route = provider.selectedChoice == UserChoice.reading
                        ? AppRoutes.prepareReading
                        : AppRoutes.assessMath;
                    Navigator.of(context).pushNamed(route);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue with $selectedCount learners',
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