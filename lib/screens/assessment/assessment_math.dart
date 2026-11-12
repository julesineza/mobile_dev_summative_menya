import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/grading.dart';
import '../../models/enums.dart';
import '../../providers/assessment_provider.dart';

class AssessmentMath extends StatefulWidget {
  const AssessmentMath({super.key});

  @override
  State<AssessmentMath> createState() => _AssessmentMathState();
}

class _AssessmentMathState extends State<AssessmentMath> {
  ResponseLevel _level = ResponseLevel.struggling;
  bool _isSaving = false;
  List<TextEditingController> _controllers = [];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(int count) {
    if (_controllers.length == count) return;
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers = List.generate(count, (_) => TextEditingController());
  }

  Future<void> _save() async {
    final provider = context.read<AssessmentProvider>();
    provider.setMathAnswers(
      _controllers.map((controller) => controller.text).toList(),
    );
    setState(() => _isSaving = true);
    try {
      await provider.saveMathResult(_level);
      if (!mounted) return;
      if (await provider.moveToNextLearner()) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.assessMath);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save math result: $error')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final questions = provider.test?.questions ?? const [];
    _syncControllers(questions.length);

    final answers = _controllers.map((controller) => controller.text).toList();
    final correct = answers
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.key < questions.length &&
              entry.value.trim().toLowerCase() ==
                  questions[entry.key].answer.trim().toLowerCase(),
        )
        .length;
    final percent = Grading.mathPercent(
      itemsCorrect: correct,
      itemsTotal: questions.length,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      '${learner?.name ?? 'Learner'}: Math quick check',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Solve each question',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    for (var index = 0; index < questions.length; index++)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _controllers[index],
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: questions[index].prompt,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    Text(
                      'Current score: $correct/${questions.length} '
                      '(${percent.toStringAsFixed(0)}%)',
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SELECT A RESPONSE LEVEL',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
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
