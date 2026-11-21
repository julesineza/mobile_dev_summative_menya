import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/grading.dart';
import '../../models/enums.dart';
import '../../providers/assessment_provider.dart';

class AssessmentReading extends StatefulWidget {
  const AssessmentReading({super.key});

  @override
  State<AssessmentReading> createState() => _AssessmentReadingState();
}

class _AssessmentReadingState extends State<AssessmentReading> {
  ResponseLevel _level = ResponseLevel.developing;
  bool _initializedLevel = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLevel) {
      final provider = context.read<AssessmentProvider>();
      final accuracy = provider.readingAccuracy ?? 0.0;
      _level = Grading.levelFromPercent(accuracy);
      _initializedLevel = true;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<AssessmentProvider>();
    final hasNext = provider.hasNextLearner;
    final learnerName = provider.currentLearner?.name ?? 'Learner';

    try {
      await provider.saveReadingResult(_level);
      if (!mounted) return;

      if (hasNext) {
        await provider.moveToNextLearner();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.prepareReading);
      } else {
        await provider.moveToNextLearner();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment completed successfully for all learners!'),
            backgroundColor: AppColors.button,
          ),
        );
      }
    } catch (error) {
      debugPrint('[AssessmentReading] save error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally for $learnerName.'),
            backgroundColor: AppColors.button,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _skipLearner() {
    final provider = context.read<AssessmentProvider>();
    if (provider.hasNextLearner) {
      provider.skipCurrentLearner();
      Navigator.of(context).pushReplacementNamed(AppRoutes.prepareReading);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final test = provider.test;
    final accuracy = provider.readingAccuracy ?? 0.0;
    final wpm = provider.readingWordsPerMinute ?? 0.0;
    final durationSec = provider.readingDurationSec;
    final errorCount = provider.errorWords.length;
    final autoSuggestedLevel = Grading.levelFromPercent(accuracy);

    final learnerIndex = provider.currentLearnerIndex + 1;
    final totalLearners = provider.totalLearners;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left, color: green, size: 20),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'LEARNER $learnerIndex OF $totalLearners • 4 OF 6',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Learner Header
                  if (learner != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            learner.initials,
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${learner.name}: Reading review',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                '${learner.className} • Duration: ${durationSec}s',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Metrics Cards
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetricItem(
                          value: '${accuracy.toStringAsFixed(0)}%',
                          label: 'Accuracy',
                          color: accuracy >= 90 ? green : (accuracy >= 70 ? Colors.amber.shade800 : AppColors.warningStroke),
                        ),
                        Container(width: 1, height: 36, color: AppColors.divider),
                        _MetricItem(
                          value: '${wpm.toStringAsFixed(0)}',
                          label: 'WPM',
                          color: AppColors.text,
                        ),
                        Container(width: 1, height: 36, color: AppColors.divider),
                        _MetricItem(
                          value: '$errorCount',
                          label: 'Mistakes',
                          color: errorCount > 0 ? AppColors.warningStroke : green,
                        ),
                        Container(width: 1, height: 36, color: AppColors.divider),
                        _MetricItem(
                          value: '${durationSec}s',
                          label: 'Time',
                          color: AppColors.text,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Passage Review with Errors
                  const Text(
                    'ASSESSED PASSAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${test?.passageText ?? ''}"',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        if (provider.errorWords.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 6),
                          const Text(
                            'Misread words:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningStroke,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: provider.errorWords.map((word) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.warningFill,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.warningStroke, width: 0.8),
                                ),
                                child: Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warningStroke,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Rubric Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SELECT A RESPONSE LEVEL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Suggested: Level ${autoSuggestedLevel.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1 - 2 - 3 Rubric Selector
                  Row(
                    children: ResponseLevel.values.map((level) {
                      final selected = _level == level;
                      final isSuggested = autoSuggestedLevel == level;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _level = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primarySoft : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? green : AppColors.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${level.value}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: selected ? green : AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _responseLevelLabel(level),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                      color: selected ? green : Colors.black87,
                                    ),
                                  ),
                                  if (isSuggested) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: selected ? Colors.white : AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Suggested',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Level Descriptions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      '1  Struggling — accuracy < 70%, needs frequent help\n'
                      '2  Developing — accuracy 70-89%, reads with support\n'
                      '3  Proficient — accuracy ≥ 90%, reads independently',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: Color(0xFF555F5A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  provider.hasNextLearner
                                      ? 'Save & next learner (${learnerIndex + 1}/$totalLearners)'
                                      : 'Finish assessment',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  if (provider.hasNextLearner) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: TextButton(
                        onPressed: _isSaving ? null : _skipLearner,
                        child: const Text(
                          'Skip this learner for now',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _responseLevelLabel(ResponseLevel level) => switch (level) {
    ResponseLevel.struggling => 'Struggling',
    ResponseLevel.developing => 'Developing',
    ResponseLevel.proficient => 'Proficient',
  };
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
