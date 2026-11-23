// owner: member 4. plan saved screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/support_options.dart';
import '../../providers/review_provider.dart';
import '../../widgets/student_widgets.dart';
import 'review_widgets.dart';

class PlanSavedScreen extends StatelessWidget {
  const PlanSavedScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    final plan = p.savedPlan;
    final activity = plan == null
        ? null
        : SupportActivity.fromStorage(plan.practiceType);

    return FlowPage(
      title: 'Support plan saved',
      subtitle: 'It now appears in this learner\'s history.',
      body: Column(
        children: [
          const Center(
            child: Icon(Icons.check_circle, size: 72, color: AppColors.button),
          ),
          const SizedBox(height: 16),
          if (plan != null)
            MenyaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity?.title ?? plan.practiceType,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.recheckDate == null
                        ? 'No recheck date yet'
                        : 'Recheck ${formatPlanDate(plan.recheckDate!)}',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.focus,
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  if (p.selectedClub != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Referred to ${p.selectedClub!.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowButton(
            label: 'View learner history',
            onPressed: () =>
                context.pushReplacement(AppRoutes.historyPath(studentId)),
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
