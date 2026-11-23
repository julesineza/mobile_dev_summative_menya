// owner: member 4. review result screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../models/assessment_result.dart';
import '../../models/enums.dart';
import '../../providers/review_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/student_widgets.dart';
import 'review_widgets.dart';

/// lets the teacher confirm or change the final level and add a note.
class ReviewResultScreen extends StatefulWidget {
  const ReviewResultScreen({super.key, required this.resultId});
  final String resultId;

  @override
  State<ReviewResultScreen> createState() => _ReviewResultScreenState();
}

class _ReviewResultScreenState extends State<ReviewResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewProvider>().loadResult(widget.resultId);
    });
  }

  Future<void> _save(ReviewProvider p) async {
    final ok = await p.saveReview();
    if (!mounted) return;
    if (ok) {
      context.push(AppRoutes.reviewSavedPath(widget.resultId));
    } else {
      showAppSnackBar(context, p.error ?? 'Could not save.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    final r = p.result;
    final loaded = r != null && r.id == widget.resultId && p.student != null;

    return FlowPage(
      title: 'Review the check',
      subtitle: 'Confirm your observations before saving.',
      stepLabel: '4 OF 6',
      body: loaded
          ? _Body(provider: p, result: r)
          : LoadGate(
              provider: p,
              needsResult: true,
              onRetry: () => p.loadResult(widget.resultId),
              builder: (_) => const SizedBox.shrink(),
            ),
      bottom: loaded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlowButton(
                  label: 'Confirm & save result',
                  loading: p.isLoading,
                  onPressed: () => _save(p),
                ),
                const SizedBox(height: 8),
                FlowTextButton(
                  label: 'Cancel',
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.home),
                ),
              ],
            )
          : null,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.result});
  final ReviewProvider provider;
  final AssessmentResult result;

  bool get _isReading => result.subject == Subject.reading;

  @override
  Widget build(BuildContext context) {
    final student = provider.student!;
    final level = provider.level ?? result.level;
    final accuracy = result.accuracy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LearnerHeader(
          student: student,
          detail:
              'Roll No. ${student.rollNo} · ${_isReading ? 'Reading' : 'Math'}',
        ),
        const SizedBox(height: 16),
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
              SectionLabel(
                _isReading ? 'Correct words per minute' : 'Items correct',
              ),
              Text(
                _isReading
                    ? (result.wordsPerMinute ?? 0).round().toString()
                    : '${result.itemsCorrect ?? 0}/${result.itemsTotal ?? 0}',
                key: const Key('review_hero_value'),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              if (accuracy != null)
                Text(
                  '${accuracy.round()}% accuracy',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MenyaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricRow('Time', '${result.durationSec}s'),
              if (_isReading)
                _MetricRow('Errors tapped', '${result.errorWords.length}'),
              if (_isReading && result.errorWords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final w in result.errorWords)
                      Chip(
                        label: Text(w),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.warningFill,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
              if (result.autoLevel != null)
                _MetricRow('App suggested', result.autoLevel!.label),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Your final level'),
        LevelSelector(selected: level, onChanged: provider.setLevel),
        if (result.autoLevel != null && result.autoLevel != level)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'You are overriding the app\'s suggestion.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ),
        const SizedBox(height: 20),
        const SectionLabel('Teacher note (optional)'),
        TextFormField(
          key: ValueKey('review-note-${result.id}'),
          initialValue: provider.reviewNotes,
          onChanged: provider.setReviewNotes,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What did you observe?',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Use this result together with your classroom observations.',
          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    ),
  );
}
