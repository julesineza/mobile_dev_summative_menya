import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/view_state.dart';
import '../../models/assessment_result.dart';
import '../../models/enums.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_widgets.dart';
import '../../core/constants/student_colors.dart';

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
    final s = p.byId(widget.studentId);

    if (s == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
          child: p.state == ViewState.loading
              ? const CircularProgressIndicator()
              : const Text(
                  'Student not found.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
        ),
      );
    }

    final results = p.resultsFor(s.id)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  icon: const Icon(Icons.chevron_left, color: AppColors.text),
                ),
                const Text(
                  'Student Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Class ${p.className} • Roll No. ${s.rollNo}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StatusBadge(status: s.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SubjectCard(subject: Subject.reading, results: results),
                  const SizedBox(height: 12),
                  _SubjectCard(subject: Subject.math, results: results),
                  const SizedBox(height: 24),
                  const Text(
                    'Assessment History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No checks yet.',
                        style: TextStyle(color: AppColors.secondaryText),
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
              color: isReading
                  ? AppColors.primarySoft
                  : StudentColors.watchFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isReading ? Icons.menu_book_outlined : Icons.calculate_outlined,
              size: 20,
              color: isReading ? AppColors.button : StudentColors.watch,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReading ? 'Reading Fluency' : 'Mathematics',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: latest?.level.color ?? AppColors.secondaryText,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            result.subject == Subject.reading ? 'Reading check' : 'Math check',
            style: const TextStyle(color: AppColors.text),
          ),
        ),
        Text(
          '${result.level.label} (${DateFormat('MMM d').format(result.createdAt)})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: result.level.color,
          ),
        ),
      ],
    ),
  );
}
