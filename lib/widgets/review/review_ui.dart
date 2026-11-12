import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class StepTopBar extends StatelessWidget {
  const StepTopBar({super.key, required this.label, this.onBack});
  final String label;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
      child: Row(
        children: [
          TextButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.button),
            child: const Text(
              '‹ Back',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class LearnerHeader extends StatelessWidget {
  const LearnerHeader({super.key, required this.name, required this.subtitle});
  final String name;
  final String subtitle;

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            _initials,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.button,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.child,
    this.highlighted = false,
    this.padding,
  });
  final Widget child;
  final bool highlighted;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.primaryBorder : AppColors.border,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AppColors.secondaryText,
    ),
  );
}

class SuccessTick extends StatelessWidget {
  const SuccessTick({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: const BoxDecoration(
      color: AppColors.primarySoft,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.check, color: AppColors.text),
  );
}

class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryOutlined = false,
    this.loading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryOutlined;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.barBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.onButton,
                  disabledBackgroundColor: AppColors.button.withValues(
                    alpha: 0.6,
                  ),
                  shape: shape,
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onButton,
                        ),
                      )
                    : Text(
                        primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: secondaryOutlined ? 48 : 40,
                child: secondaryOutlined
                    ? OutlinedButton(
                        onPressed: loading ? null : onSecondary,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.button,
                          side: const BorderSide(
                            color: AppColors.primaryBorder,
                          ),
                          shape: shape,
                        ),
                        child: Text(
                          secondaryLabel!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : TextButton(
                        onPressed: loading ? null : onSecondary,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryText,
                        ),
                        child: Text(
                          secondaryLabel!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
