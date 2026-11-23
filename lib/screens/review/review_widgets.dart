// owner: member 4. small widgets shared by the review screens.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/view_state.dart';
import '../../models/enums.dart';
import '../../models/student.dart';
import '../../providers/review_provider.dart';
import '../../widgets/student_widgets.dart';

/// page frame with back link, step label, title, body and bottom bar.
class FlowPage extends StatelessWidget {
  const FlowPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.stepLabel,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final String? stepLabel;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 24, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                    child: const Text(
                      '‹ Back',
                      style: TextStyle(
                        color: AppColors.button,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (stepLabel != null)
                    Text(
                      stepLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    body,
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// shows a spinner or retry while loading, then builds [builder].
class LoadGate extends StatelessWidget {
  const LoadGate({
    super.key,
    required this.provider,
    required this.onRetry,
    required this.builder,
    this.needsResult = false,
  });

  final ReviewProvider provider;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context) builder;
  final bool needsResult;

  @override
  Widget build(BuildContext context) {
    final missing =
        provider.student == null || (needsResult && provider.result == null);
    if (!missing) return builder(context);
    if (provider.state == ViewState.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              provider.error ?? 'Could not load.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.warningStroke),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (provider.state == ViewState.success && provider.student != null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No saved checks for this learner yet.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// initials circle with name and roll number.
class LearnerHeader extends StatelessWidget {
  const LearnerHeader({super.key, required this.student, this.detail});
  final Student student;
  final String? detail;

  String get _initials {
    final parts = student.name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primarySoft,
        child: Text(
          _initials,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.button,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            Text(
              detail ?? 'Roll No. ${student.rollNo}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// green action button used at the bottom of each page.
class FlowButton extends StatelessWidget {
  const FlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: AppColors.onButton,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}

/// quiet text action under the main button.
class FlowTextButton extends StatelessWidget {
  const FlowTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 44,
    child: TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// small caption above a group of fields.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.secondaryText,
      ),
    ),
  );
}

/// pill showing a level name.
class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// struggling / developing / proficient selector.
class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final ResponseLevel selected;
  final ValueChanged<ResponseLevel> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final l in ResponseLevel.values) ...[
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(l),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected == l
                    ? l.colorOf(context).withAlpha(25)
                    : Colors.white,
                border: Border.all(
                  color: selected == l ? l.colorOf(context) : AppColors.border,
                  width: selected == l ? 1.6 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${l.value}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    l.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected == l
                          ? l.colorOf(context)
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (l != ResponseLevel.values.last) const SizedBox(width: 8),
      ],
    ],
  );
}
