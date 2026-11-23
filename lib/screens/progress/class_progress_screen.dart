import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/view_state.dart';
import '../../models/assessment_result.dart';
import '../../models/enums.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_widgets.dart';
import '../../core/constants/student_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/assessment_colors.dart';

class ClassProgressScreen extends StatefulWidget {
  const ClassProgressScreen({super.key});

  @override
  State<ClassProgressScreen> createState() => _ClassProgressScreenState();
}

class _ClassProgressScreenState extends State<ClassProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();
    final c = context.assessmentColors;

    if (p.state == ViewState.loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final onTrack = p.countOf(SupportStatus.onTrack);
    final watch = p.countOf(SupportStatus.watch);
    final support = p.countOf(SupportStatus.needsSupport);
    final results = p.results;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Class Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 16),
            SyncErrorBanner(message: p.resultsError),
            MenyaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Class overview',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${p.total} students · ${p.className}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.studentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _StackedBar(
                    counts: {
                      SupportStatus.onTrack: onTrack,
                      SupportStatus.watch: watch,
                      SupportStatus.needsSupport: support,
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _Legend(
                        color: SupportStatus.onTrack.colorOf(context),
                        text: 'On track ($onTrack)',
                      ),
                      _Legend(
                        color: SupportStatus.watch.colorOf(context),
                        text: 'Watch ($watch)',
                      ),
                      _Legend(
                        color: SupportStatus.needsSupport.colorOf(context),
                        text: 'Support ($support)',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Subject Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 12),
            _SubjectBar(
              label: 'Reading Fluency',
              percent: _competentPercent(results, Subject.reading),
            ),
            const SizedBox(height: 14),
            _SubjectBar(
              label: 'Mathematics',
              percent: _competentPercent(results, Subject.math),
            ),
            const SizedBox(height: 24),
            Text(
              'Students Needing Attention',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 10),
            if (p.needsAttention.isEmpty)
              Text(
                'No learners flagged right now.',
                style: TextStyle(color: c.secondaryText),
              )
            else
              for (final s in p.needsAttention)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AttentionRow(
                    student: s,
                    reason: _reason(results, s.id),
                    onTap: () => context.push('/students/${s.id}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Returns the percentage of students who are competent in the given subject, or null if no data.
double? _competentPercent(List<AssessmentResult> results, Subject subject) {
  final latest = <String, AssessmentResult>{};
  for (final r in results.where((r) => r.subject == subject)) {
    final cur = latest[r.studentId];
    if (cur == null || r.createdAt.isAfter(cur.createdAt)) {
      latest[r.studentId] = r;
    }
  }
  if (latest.isEmpty) return null;
  final ok = latest.values
      .where((r) => r.level == ResponseLevel.proficient)
      .length;
  return ok / latest.length * 100;
}

/// Returns a string like "Struggling: Reading Fluency" or "Needs support".
String _reason(List<AssessmentResult> results, String studentId) {
  final mine =
      results
          .where(
            (r) =>
                r.studentId == studentId && r.level == ResponseLevel.struggling,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (mine.isEmpty) return 'Needs support';
  return 'Struggling: ${mine.first.subject == Subject.reading ? 'Reading Fluency' : 'Mathematics'}';
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.counts});
  final Map<SupportStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final parts = counts.entries.where((e) => e.value > 0).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 14,
        child: parts.isEmpty
            ? ColoredBox(
                color: context.assessmentColors.divider,
                child: const SizedBox.expand(),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in parts)
                    Expanded(
                      flex: e.value,
                      child: ColoredBox(color: e.key.colorOf(context)),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: context.assessmentColors.secondaryText,
        ),
      ),
    ],
  );
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.label, required this.percent});
  final String label;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    final pct = percent;
    final color = pct == null
        ? c.secondaryText
        : pct >= 70
        ? context.studentGreen
        : pct >= 50
        ? context.palette.watchText
        : c.warningStroke;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
            ),
            const Spacer(),
            Text(
              pct == null ? 'No data yet' : '${pct.round()}% Competent',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct ?? 0) / 100,
            minHeight: 8,
            color: color,
            backgroundColor: c.divider,
          ),
        ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.student,
    required this.reason,
    required this.onTap,
  });
  final Student student;
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    final radius = BorderRadius.circular(14);
    return Material(
      color: c.warningFill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.warningStroke.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              StudentAvatar(name: student.name),
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
                      reason,
                      style: TextStyle(fontSize: 12, color: c.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.error_outline, color: c.warningStroke),
            ],
          ),
        ),
      ),
    );
  }
}
