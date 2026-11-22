import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/assessment_colors.dart';
import '../../providers/assessment_provider.dart';

class PrepareReadingPage extends StatelessWidget {
  const PrepareReadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final test = provider.test;
    final passage =
        test?.passageText ??
        'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.';
    final wordCount = passage
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    final learnerIndex = provider.currentLearnerIndex + 1;
    final totalLearners = provider.totalLearners;

    return Scaffold(
      backgroundColor: context.assessmentColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
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
                  Text(
                    '2 OF 6',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: context.assessmentColors.secondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  Text(
                    'Prepare reading',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Place the reading passage in front of the learner before starting the timer.',
                    style: TextStyle(
                      fontSize: 15,
                      color: context.assessmentColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Learner Card
                  if (learner != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.assessmentColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.assessmentColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                context.assessmentColors.primarySoft,
                            child: Text(
                              learner.initials,
                              style: TextStyle(
                                color: green,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  learner.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '${learner.className} • English reading',
                                  style: TextStyle(
                                    color:
                                        context.assessmentColors.secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: context.assessmentColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Learner $learnerIndex of $totalLearners',
                              style: TextStyle(
                                color: green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 24),

                  // Section title for passage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ENGLISH PASSAGE (LEVEL 2)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.assessmentColors.secondaryText,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        '$wordCount words',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Passage Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.assessmentColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"$passage"',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: context.assessmentColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Teacher Instructions
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.instructionBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.assessmentColors.primaryBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Testing instructions',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '1. Ask the learner to read the passage out loud.\n'
                          '2. Tap any word they misread, skip, or hesitate on for >3s.\n'
                          '3. Tap "Finish" as soon as they finish the last word.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: context.assessmentColors.instructionText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action
            Container(
              color: context.assessmentColors.surface,
              padding: EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.takeReading);
                  },
                  icon: Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(
                    'Start reading check',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
