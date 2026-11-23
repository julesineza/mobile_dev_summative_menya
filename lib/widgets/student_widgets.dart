import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../core/constants/student_colors.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/assessment_colors.dart';

extension SupportStatusUi on SupportStatus {
  String get label => switch (this) {
    SupportStatus.onTrack => 'On track',
    SupportStatus.watch => 'Watch',
    SupportStatus.needsSupport => 'Needs support',
  };
  Color colorOf(BuildContext context) {
    final c = context.assessmentColors;
    return switch (this) {
      SupportStatus.onTrack => context.studentGreen,
      SupportStatus.watch => context.palette.watchText,
      SupportStatus.needsSupport => c.warningStroke,
    };
  }

  Color fillOf(BuildContext context) {
    final c = context.assessmentColors;
    return switch (this) {
      SupportStatus.onTrack => c.primarySoft,
      SupportStatus.watch => c.amberSoft,
      SupportStatus.needsSupport => c.warningFill,
    };
  }
}

extension ResponseLevelUi on ResponseLevel {
  String get label => switch (this) {
    ResponseLevel.struggling => 'Struggling',
    ResponseLevel.developing => 'Developing',
    ResponseLevel.proficient => 'Proficient',
  };
  Color colorOf(BuildContext context) {
    final c = context.assessmentColors;
    return switch (this) {
      ResponseLevel.struggling => c.warningStroke,
      ResponseLevel.developing => context.palette.watchText,
      ResponseLevel.proficient => context.studentGreen,
    };
  }
}

String initialsOf(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();

String lastAssessedLabel(DateTime? d) {
  if (d == null) return 'Not assessed yet';
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return 'Last assessed today';
  if (days == 1) return 'Last assessed yesterday';
  return 'Last assessed ${days}d ago';
}

// Card with surface background, rounded corners, and border.
class MenyaCard extends StatelessWidget {
  const MenyaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

// Initials circle, with optional status dot (roster rows).
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.name,
    this.status,
    this.radius = 20,
  });
  final String name;
  final SupportStatus? status;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: c.primarySoft,
          child: Text(
            initialsOf(name),
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.w700,
              color: context.studentGreen,
            ),
          ),
        ),
        if (status != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: status!.colorOf(context),
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// Status badge used in roster rows and profile header.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final SupportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.colorOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: status.fillOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Filter pill used in roster filter bar.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? AppColors.button : c.border),
    );
    return Material(
      color: selected ? AppColors.button : c.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onButton : c.text,
            ),
          ),
        ),
      ),
    );
  }
}

// Roster row card, with avatar, name, subtitle, and chevron.
class StudentRow extends StatelessWidget {
  const StudentRow({
    super.key,
    required this.student,
    required this.subtitle,
    this.onTap,
  });
  final Student student;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    final radius = BorderRadius.circular(14);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              StudentAvatar(name: student.name, status: student.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

// Red error banner. Shows nothing when message is null.
// The close button only appears when onDismiss is given.
class SyncErrorBanner extends StatelessWidget {
  const SyncErrorBanner({super.key, required this.message, this.onDismiss});
  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    final c = context.assessmentColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: c.warningFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.warningStroke),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: c.warningStroke),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: c.text)),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, size: 18, color: c.text),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
