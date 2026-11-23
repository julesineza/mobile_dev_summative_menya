// owner: member 4. result saved screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../providers/review_provider.dart';
import '../../widgets/student_widgets.dart';
import 'review_widgets.dart';

class ResultSavedScreen extends StatelessWidget {
  const ResultSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    final student = p.student;
    final result = p.result;
    final level = p.level;

    return FlowPage(
      title: 'Result saved',
      subtitle: 'The result is now part of the learner\'s history.',
      stepLabel: '4 OF 6',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.check_circle, size: 72, color: AppColors.button),
          ),
          const SizedBox(height: 16),
          if (student != null && level != null)
            MenyaCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  LevelChip(label: level.label, color: level.color),
                ],
              ),
            ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowButton(
            label: 'Plan a little support',
            onPressed: student == null
                ? null
                : () => context.push(
                    AppRoutes.supportPlanPath(student.id, resultId: result?.id),
                  ),
          ),
          const SizedBox(height: 8),
          FlowTextButton(
            label: 'Back to Home',
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
