import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_dev_summative_menya/app_routes.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';

class StartAssessment extends StatelessWidget {
  const StartAssessment({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: colorScheme.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 27),

              // Page title
              const Text(
                'New Assessment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 27),

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
                        children: [
                          const TextSpan(
                            text: 'Select a subject to begin a quick check. Class ',
                          ),
                          TextSpan(
                            text: 'P3-A',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' is active.'),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.selectClass);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.button,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 23),

              // Reading card
              SubjectCard(
                title: 'Soma (Reading)',
                description: 'Fluency, recognition, and comprehension',
                icon: Icons.menu_book_outlined,
                color: colorScheme.primary,
                iconBackground: const Color(0xFFEAF4EC),
                onTap: () {
                  context.read<AssessmentProvider>().setSelectedAssessment(
                        UserChoice.reading,
                      );
                  Navigator.of(context).pushNamed(AppRoutes.selectLearners);
                },
              ),

              const SizedBox(height: 16),

              // Mathematics card
              SubjectCard(
                title: 'Imibare (Mathematics)',
                description: 'Arithmetic, division, and basic logic',
                icon: Icons.calculate_outlined,
                color: const Color(0xFFFF6500),
                iconBackground: const Color(0xFFFFF1E7),
                onTap: () {
                  context.read<AssessmentProvider>().setSelectedAssessment(
                        UserChoice.math,
                      );
                  Navigator.of(context).pushNamed(AppRoutes.selectLearners);
                },
              ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(23, 23, 20, 21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9E5DE), width: 1),
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
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right, color: color, size: 23),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Subject title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 3),

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
