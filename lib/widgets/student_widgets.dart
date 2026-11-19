import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../models/enums.dart';
import '../models/student.dart';

extension SupportStatusUi on SupportStatus {
  String get label => switch (this) {
    SupportStatus.onTrack => 'On track',
    SupportStatus.watch => 'Watch',
    SupportStatus.needsSupport => 'Needs support',
  };
  Color get color => switch (this) {
    SupportStatus.onTrack => AppColors.button,
    SupportStatus.watch => AppColors.watch,
    SupportStatus.needsSupport => AppColors.warningStroke,
  };
  Color get fill => switch (this) {
    SupportStatus.onTrack => AppColors.primarySoft,
    SupportStatus.watch => AppColors.watchFill,
    SupportStatus.needsSupport => AppColors.warningFill,
  };
}

extension ResponseLevelUi on ResponseLevel {
  String get label => switch (this) {
    ResponseLevel.struggling => 'Struggling',
    ResponseLevel.developing => 'Developing',
    ResponseLevel.proficient => 'Proficient',
  };
  Color get color => switch (this) {
    ResponseLevel.struggling => AppColors.warningStroke,
    ResponseLevel.developing => AppColors.watch,
    ResponseLevel.proficient => AppColors.button,
  };
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

// Card with white background, rounded corners, and border.
class MenyaCard extends StatelessWidget {
  const MenyaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            initialsOf(name),
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.w700,
              color: AppColors.button,
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
                color: status!.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: status.fill,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: status.color),
    ),
    child: Text(
      status.label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: status.color,
      ),
    ),
  );
}

/// "All (45)" / "Needs Support (8)" / "Watch (5)"
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
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? AppColors.button : AppColors.border),
    );
    return Material(
      color: selected ? AppColors.button : Colors.white,
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
              color: selected ? AppColors.onButton : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// One roster row.
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
    final radius = BorderRadius.circular(14);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
