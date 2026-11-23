import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_dev_summative_menya/app_routes.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/theme/assessment_colors.dart';

class StartAssessment extends StatelessWidget {
  const StartAssessment({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<AssessmentProvider>();

    final isDark = theme.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: colorScheme.surface,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 27),

              // Page title
              Text(
                'New Assessment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 27),

              // A save that Firestore rejected after we moved on (writes
              // run in the background so the flow never hangs offline).
              if (provider.syncError != null) ...[
                Container(
                  padding: EdgeInsets.fromLTRB(14, 6, 4, 6),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A result could not be saved: ${provider.syncError}',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: provider.clearSyncError,
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.3,
                        ),
                        children: provider.hasClass
                            ? [
                                TextSpan(
                                  text: 'Select a subject to begin a quick check. Class ',
                                ),
                                TextSpan(
                                  text: provider.selectedClassName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' is active.'),
                              ]
                            : [
                                TextSpan(
                                  text: 'No class selected. Create or choose a class to start a quick check.',
                                ),
                              ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(AppRoutes.selectClass);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.button,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Change',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 23),

              // Reading card
              SubjectCard(
                title: 'Soma (Reading)',
                description: 'Fluency, recognition, and comprehension',
                icon: Icons.menu_book_outlined,
                color: colorScheme.primary,
                iconBackground: context.assessmentColors.primarySoft,
                onTap: () {
                  context.read<AssessmentProvider>().setSelectedAssessment(
                    UserChoice.reading,
                  );
                  context.push(AppRoutes.selectLearners);
                },
              ),

              SizedBox(height: 16),

              // Mathematics card
              SubjectCard(
                title: 'Imibare (Mathematics)',
                description: 'Arithmetic, division, and basic logic',
                icon: Icons.calculate_outlined,
                color: context.assessmentColors.mathText,
                iconBackground: context.assessmentColors.mathSoft,
                onTap: () {
                  context.read<AssessmentProvider>().setSelectedAssessment(
                    UserChoice.math,
                  );
                  context.push(AppRoutes.selectLearners);
                },
              ),

              SizedBox(height: 24),

              // Set up custom test card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.assessmentColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.assessmentColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.assessmentColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.tune_outlined,
                        color: AppColors.button,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set up a custom test',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: context.assessmentColors.text,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Customize words, passage or math problems',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.assessmentColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.setupReading);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.button,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Set up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Subject Card
class SubjectCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color iconBackground;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: context.assessmentColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(23, 23, 20, 21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.assessmentColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 25),
                  ),

                  Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(
                      color: context.assessmentColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right, color: color, size: 23),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Subject title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 3),

              // Description
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
