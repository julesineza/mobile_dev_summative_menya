import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/student_colors.dart';
import '../../core/date_labels.dart';
import '../../core/theme/app_theme.dart';
import '../../models/assessment_session.dart';
import '../../models/enums.dart';
import '../../models/school_class.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.dateLabel,
    required this.name,
    required this.onSettings,
  });

  final String dateLabel;
  final String name;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

/// "45 students · 5 on watch" card with a class chip. When the teacher has
/// several classes the chip opens a menu to switch between them.
class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.total,
    required this.watch,
    required this.classes,
    required this.selected,
    required this.onSelect,
  });

  final int total;
  final int watch;
  final List<SchoolClass> classes;
  final SchoolClass selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.button,
            ),
          ),
          if (classes.length > 1)
            const Icon(Icons.arrow_drop_down, color: AppColors.button),
        ],
      ),
    );

    return _DashCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLASS OVERVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$total students',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' · $watch on watch',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: StudentColors.watch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (classes.length > 1)
              PopupMenuButton<String>(
                tooltip: 'Switch class',
                onSelected: onSelect,
                itemBuilder: (_) => [
                  for (final c in classes)
                    PopupMenuItem(value: c.id, child: Text(c.name)),
                ],
                child: chip,
              )
            else
              chip,
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final String caption;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            caption,
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class QuickCheckCta extends StatelessWidget {
  const QuickCheckCta({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.button,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a quick check',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose reading or mathematics',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentCheckTile extends StatelessWidget {
  const RecentCheckTile({super.key, required this.session});
  final AssessmentSession session;

  @override
  Widget build(BuildContext context) {
    final isReading = session.subject == Subject.reading;
    final count = session.studentIds.length;
    return _DashCard(
      child: ListTile(
        leading: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: isReading ? AppColors.primarySoft : StudentColors.watchFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isReading ? Icons.menu_book_rounded : Icons.calculate_rounded,
            size: 18,
            color: isReading ? AppColors.button : StudentColors.watch,
          ),
        ),
        title: Text(
          isReading ? 'Reading check' : 'Math check',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${checkTimeLabel(session.createdAt)} · $count '
          '${count == 1 ? 'learner' : 'learners'}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
      ),
    );
  }
}

/// Reused for "no classes yet" and "no quick checks yet".
class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 36, color: AppColors.secondaryText),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 12),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class InlineLoading extends StatelessWidget {
  const InlineLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _DashCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.warningStroke),
      ),
    ),
  );
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? null : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: BorderSide(color: isDark ? Colors.white12 : AppColors.border),
      ),
      child: child,
    );
  }
}
