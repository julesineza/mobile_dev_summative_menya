// owner: member 4. learner history screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/support_options.dart';
import '../../models/assessment_result.dart';
import '../../models/enums.dart';
import '../../models/support_plan.dart';
import '../../providers/review_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/student_widgets.dart';
import 'review_widgets.dart';

/// every saved check for a learner with its plan underneath.
class LearnerHistoryScreen extends StatefulWidget {
  const LearnerHistoryScreen({super.key, required this.studentId});
  final String studentId;

  @override
  State<LearnerHistoryScreen> createState() => _LearnerHistoryScreenState();
}

class _LearnerHistoryScreenState extends State<LearnerHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewProvider>().loadStudent(widget.studentId);
    });
  }

  Future<void> _onAction(
    ReviewProvider p,
    SupportPlan plan,
    _PlanAction action,
  ) async {
    bool ok = true;
    switch (action) {
      case _PlanAction.rechecked:
        ok = await p.markRechecked(plan);
      case _PlanAction.close:
        ok = await p.closePlan(plan);
      case _PlanAction.setDate:
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: plan.recheckDate ?? oneWeekFrom(now),
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: DateTime(now.year + 1, now.month, now.day),
        );
        if (picked == null) return;
        ok = await p.scheduleRecheck(plan, picked);
      case _PlanAction.delete:
        final sure = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this plan?'),
            content: const Text(
              'The saved check stays; only the plan is removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (sure != true) return;
        ok = await p.deletePlan(plan);
    }
    if (!mounted) return;
    showAppSnackBar(
      context,
      ok ? 'Plan updated.' : (p.error ?? 'Could not update the plan.'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    final student = p.student;
    final loaded = student != null && student.id == widget.studentId;

    return FlowPage(
      title: 'Saved checks',
      subtitle: 'Results and follow-up plans stay together.',
      body: !loaded
          ? LoadGate(
              provider: p,
              onRetry: () => p.loadStudent(widget.studentId),
              builder: (_) => const SizedBox.shrink(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LearnerHeader(student: student),
                const SizedBox(height: 16),
                if (p.results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No saved checks for this learner yet.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ),
                  ),
                for (final r in p.results)
                  _CheckCard(
                    result: r,
                    plan: p.planForResult(r.id),
                    onReview: () => context.push(AppRoutes.reviewPath(r.id)),
                    onPlan: () => context.push(
                      AppRoutes.supportPlanPath(student.id, resultId: r.id),
                    ),
                    onAction: (plan, a) => _onAction(p, plan, a),
                  ),
              ],
            ),
      bottom: FlowButton(
        label: 'Back to Home',
        onPressed: () => context.go(AppRoutes.home),
      ),
    );
  }
}

enum _PlanAction { setDate, rechecked, close, delete }

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.result,
    required this.plan,
    required this.onReview,
    required this.onPlan,
    required this.onAction,
  });
  final AssessmentResult result;
  final SupportPlan? plan;
  final VoidCallback onReview;
  final VoidCallback onPlan;
  final void Function(SupportPlan plan, _PlanAction action) onAction;

  String get _summary {
    if (result.subject == Subject.reading) {
      final wpm = (result.wordsPerMinute ?? 0).round();
      final acc = result.accuracy == null
          ? ''
          : ' · ${result.accuracy!.round()}% accuracy';
      return '$wpm correct words/min$acc';
    }
    return '${result.itemsCorrect ?? 0}/${result.itemsTotal ?? 0} correct';
  }

  @override
  Widget build(BuildContext context) {
    final subject = result.subject == Subject.reading ? 'Reading' : 'Math';
    final plan = this.plan;
    final activity = plan == null
        ? null
        : SupportActivity.fromStorage(plan.practiceType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MenyaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onReview,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$subject check · ${DateFormat('d MMM yyyy').format(result.createdAt)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      LevelChip(
                        label: result.level.label,
                        color: result.level.colorOf(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _summary,
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  Text(
                    '${result.durationSec}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, color: AppColors.divider),
            if (plan == null)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'No support plan yet',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                  TextButton(
                    onPressed: onPlan,
                    child: const Text('Plan support'),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                        const SizedBox(height: 4),
                        Text(
                          plan.recheckDate == null
                              ? 'No recheck date yet'
                              : 'Recheck ${formatPlanDate(plan.recheckDate!)}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.focus,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LevelChip(
                          label: switch (plan.status) {
                            PlanStatus.active => 'Active',
                            PlanStatus.rechecked => 'Rechecked',
                            PlanStatus.closed => 'Closed',
                          },
                          color: plan.status == PlanStatus.active
                              ? AppColors.button
                              : AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_PlanAction>(
                    key: Key('plan_menu_${plan.id}'),
                    onSelected: (a) => onAction(plan, a),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _PlanAction.setDate,
                        child: Text('Set recheck date'),
                      ),
                      PopupMenuItem(
                        value: _PlanAction.rechecked,
                        child: Text('Mark rechecked'),
                      ),
                      PopupMenuItem(
                        value: _PlanAction.close,
                        child: Text('Close plan'),
                      ),
                      PopupMenuItem(
                        value: _PlanAction.delete,
                        child: Text('Delete plan'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
