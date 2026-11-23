// owner: member 4. schedule recheck screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/support_options.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/student_widgets.dart';
import 'review_widgets.dart';

class ScheduleRecheckScreen extends StatelessWidget {
  const ScheduleRecheckScreen({super.key, required this.studentId});
  final String studentId;

  Future<void> _pickDate(BuildContext context, ReviewProvider p) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: p.recheckDate ?? oneWeekFrom(now),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) p.setRecheckDate(picked);
  }

  Future<void> _save(BuildContext context, ReviewProvider p) async {
    final date = p.recheckDate;
    if (date == null || !isValidRecheckDate(date)) {
      showAppSnackBar(
        context,
        'Choose today or a later date for the recheck.',
        isError: true,
      );
      return;
    }
    final teacherId = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final ok = await p.savePlan(teacherId: teacherId);
    if (!context.mounted) return;
    if (ok) {
      context.pushReplacement(AppRoutes.planSavedPath(studentId));
    } else {
      showAppSnackBar(context, p.error ?? 'Could not save.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    final student = p.student;
    final activity = p.activity;
    final date = p.recheckDate;

    return FlowPage(
      title: 'When will you recheck?',
      subtitle: 'Leave time for the learner to practise.',
      stepLabel: '6 OF 6',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (student != null) LearnerHeader(student: student),
          const SizedBox(height: 16),
          if (activity != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                border: Border.all(color: AppColors.primaryBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Chosen support'),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  if (p.planNote.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.planNote.trim(),
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          MenyaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Recheck date'),
                InkWell(
                  key: const Key('recheck_date_field'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickDate(context, p),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            date == null ? 'Pick a date' : formatPlanDate(date),
                            style: TextStyle(
                              color: date == null
                                  ? AppColors.secondaryText
                                  : AppColors.text,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('one_week_button'),
                  onPressed: p.useOneWeek,
                  child: const Text('Use one week from today'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The plan will appear in this learner\'s saved history. '
            'No message or calendar invitation is sent.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowButton(
            label: 'Save support plan',
            loading: p.isLoading,
            onPressed: () => _save(context, p),
          ),
          const SizedBox(height: 8),
          FlowTextButton(
            label: 'Back to activity',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
