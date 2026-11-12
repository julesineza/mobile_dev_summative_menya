import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../models/enums.dart';
import '../../providers/assessment_provider.dart';

class AssessmentReading extends StatefulWidget {
  const AssessmentReading({super.key});

  @override
  State<AssessmentReading> createState() => _AssessmentReadingState();
}

class _AssessmentReadingState extends State<AssessmentReading> {
  ResponseLevel _level = ResponseLevel.struggling;
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<AssessmentProvider>();
      await provider.saveReadingResult(_level);
      if (!mounted) return;
      if (await provider.moveToNextLearner()) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.takeReading);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      debugPrint('[AssessmentReading] save failed: $error');
      debugPrintStack();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reading result: $error')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final test = provider.test;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Back',
                  ),
                  if (learner != null)
                    Expanded(
                      child: Text(
                        '${learner.name}: Reading review',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  Text(
                    '${provider.readingDurationSec}s',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Final reading verdict',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Text(
                    test?.passageText ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${provider.errorWords.length} mistakes · '
                '${provider.readingAccuracy?.toStringAsFixed(1) ?? '0.0'}% accuracy · '
                '${provider.readingWordsPerMinute?.toStringAsFixed(1) ?? '0.0'} WPM',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'SELECT A RESPONSE LEVEL',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: ResponseLevel.values.map((level) {
                  final selected = _level == level;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _level = level),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? AppColors.warningFill
                              : null,
                          side: BorderSide(
                            color: selected
                                ? AppColors.warningStroke
                                : AppColors.button,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${level.value}'),
                            Text(
                              _responseLevelLabel(level),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : (provider.hasNextLearner
                              ? 'Save & next student'
                              : 'Finish assessment'),
                  ),
                ),
              ),
            ],
          ),
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
