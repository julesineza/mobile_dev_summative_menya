import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/view_state.dart';
import '../../models/assessment_result.dart';
import '../../models/enums.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_widgets.dart';
import '../../core/constants/student_colors.dart';
import '../../core/theme/assessment_colors.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key, required this.studentId});
  final String studentId;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();
    final c = context.assessmentColors;
    final s = p.byId(widget.studentId);

    if (s == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.text,
          elevation: 0,
        ),
        body: Center(
          child: p.state == ViewState.loading
              ? const CircularProgressIndicator()
              : Text(
                  'Student not found.',
                  style: TextStyle(color: c.secondaryText),
                ),
        ),
      );
    }

    final results = p.resultsFor(s.id)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.push('/assess', extra: s),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: AppColors.onButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text(
                'Start Quick Check Now',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.chevron_left, color: c.text),
                ),
                Text(
                  'Student Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        StudentAvatar(name: s.name, radius: 36),
                        const SizedBox(height: 12),
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Class ${p.className} • Roll No. ${s.rollNo}',
                          style: TextStyle(color: c.secondaryText),
                        ),
                        const SizedBox(height: 10),
                        StatusBadge(status: s.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SyncErrorBanner(message: p.resultsError),
                  _SubjectCard(subject: Subject.reading, results: results),
                  const SizedBox(height: 12),
                  _SubjectCard(subject: Subject.math, results: results),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.historyPath(s.id)),
                    icon: const Icon(Icons.history),
                    label: const Text('Review & support plans'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Assessment History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No checks yet.',
                        style: TextStyle(color: c.secondaryText),
                      ),
                    )
                  else
                    for (final r in results) _HistoryRow(result: r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.results});
  final Subject subject;
  final List<AssessmentResult> results; // newest first

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    final mine = results.where((r) => r.subject == subject).toList();
    final latest = mine.isEmpty ? null : mine.first;
    final prev = mine.length > 1 ? mine[1] : null;
    final score = latest?.accuracy;
    final change = (score != null && prev?.accuracy != null)
        ? score - prev!.accuracy!
        : null;
    final isReading = subject == Subject.reading;

    final trend = change == null
        ? 'First check'
        : (change >= 0 ? 'Improving' : 'Declining');
    final detail = latest == null
        ? 'Not assessed yet'
        : 'Level: ${latest.level.label} • $trend';
    final arrow = change == null ? '' : (change >= 0 ? '▲ ' : '▼ ');
    final trailing = score == null ? '' : '$arrow${score.round()}%';

    return MenyaCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isReading ? c.primarySoft : c.mathSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isReading ? Icons.menu_book_outlined : Icons.calculate_outlined,
              size: 20,
              color: isReading ? context.studentGreen : c.mathText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReading ? 'Reading Fluency' : 'Mathematics',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: c.secondaryText),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: latest?.level.colorOf(context) ?? c.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.result});
  final AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.assessmentColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.subject == Subject.reading
                  ? 'Reading check'
                  : 'Math check',
              style: TextStyle(color: c.text),
            ),
          ),
          Text(
            '${result.level.label} (${DateFormat('MMM d').format(result.createdAt)})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: result.level.colorOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
