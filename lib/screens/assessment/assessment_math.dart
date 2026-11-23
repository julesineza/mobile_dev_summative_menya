import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/assessment_colors.dart';
import '../../core/failure.dart';
import '../../core/grading.dart';
import '../../models/enums.dart';
import '../../providers/assessment_provider.dart';

class AssessmentMath extends StatefulWidget {
  const AssessmentMath({super.key});

  @override
  State<AssessmentMath> createState() => _AssessmentMathState();
}

class _AssessmentMathState extends State<AssessmentMath> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = true;
  bool _isSaving = false;

  /// Map of question index -> teacher-recorded answer
  final Map<int, String> _answers = {};

  /// Overridden response level; if null, autoLevel is used.
  ResponseLevel? _manualLevel;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAssessment());
  }

  /// Loads the test and opens the session one after the other (they used to
  /// run in parallel, loading the test twice), and reports failures.
  Future<void> _initAssessment() async {
    if (!mounted) return;
    final provider = context.read<AssessmentProvider>();
    try {
      await provider.ensureSession();
    } catch (error) {
      debugPrint('[AssessmentMath] session error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is Failure
                ? error.message
                : 'Could not start the session. It will be retried when you save.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _isTimerRunning = false);
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  void _markAnswer(int index, String value) {
    setState(() {
      _answers[index] = value;
    });
  }

  Future<void> _save() async {
    final provider = context.read<AssessmentProvider>();
    final questions = provider.test?.questions ?? const [];
    final total = questions.length;

    // Convert map to list of answers matching questions order
    final answerList = List.generate(total, (i) => _answers[i] ?? '');
    provider.setMathAnswers(answerList);

    // Calculate score & level
    final correct = questions.asMap().entries.where((entry) {
      final ans = _answers[entry.key] ?? '';
      return ans.trim().toLowerCase() ==
          entry.value.answer.trim().toLowerCase();
    }).length;

    final percent = Grading.mathPercent(
      itemsCorrect: correct,
      itemsTotal: total,
    );
    final autoLevel = Grading.levelFromPercent(percent);
    final effectiveLevel = _manualLevel ?? autoLevel;

    setState(() => _isSaving = true);
    _pauseTimer();

    final hasNext = provider.hasNextLearner;
    final learnerName = provider.currentLearner?.name ?? 'Learner';

    try {
      await provider.saveMathResult(
        effectiveLevel,
        durationSec: _elapsedSeconds,
      );

      if (!mounted) return;

      if (hasNext) {
        await provider.moveToNextLearner();
        if (!mounted) return;
        // Reset state for next learner in-place
        setState(() {
          _answers.clear();
          _manualLevel = null;
          _elapsedSeconds = 0;
          _isSaving = false;
        });
        _startTimer();
      } else {
        await provider.moveToNextLearner();
        if (!mounted) return;
        context.go(AppRoutes.assess);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Math assessment completed for all learners!'),
            backgroundColor: AppColors.button,
          ),
        );
      }
    } catch (error) {
      debugPrint('[AssessmentMath] save error: $error');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is Failure
                  ? error.message
                  : 'Could not save $learnerName\'s result. Please try again.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _skipLearner() async {
    final provider = context.read<AssessmentProvider>();
    if (provider.hasNextLearner) {
      provider.skipCurrentLearner();
      setState(() {
        _answers.clear();
        _manualLevel = null;
        _elapsedSeconds = 0;
      });
      _startTimer();
    } else {
      // Last learner skipped: close the session so it is not left open.
      _pauseTimer();
      await provider.finishSession();
      if (!mounted) return;
      context.go(AppRoutes.assess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final test = provider.test;
    final questions = test?.questions ?? const [];
    final learnerIndex = provider.currentLearnerIndex + 1;
    final totalLearners = provider.totalLearners;

    const green = AppColors.button;
    final bg = context.assessmentColors.background;
    final border = context.assessmentColors.border;

    // Score calculations
    final correctCount = questions.asMap().entries.where((entry) {
      final ans = _answers[entry.key] ?? '';
      return ans.trim().toLowerCase() ==
          entry.value.answer.trim().toLowerCase();
    }).length;

    final percent = Grading.mathPercent(
      itemsCorrect: correctCount,
      itemsTotal: questions.length,
    );
    final autoLevel = Grading.levelFromPercent(percent);
    final activeLevel = _manualLevel ?? autoLevel;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left, color: green, size: 20),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.mathSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 14,
                          color: context.assessmentColors.mathText,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'MATH CHECK',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: context.assessmentColors.mathText,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Learner Profile Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: context.assessmentColors.mathSoft,
                          child: Text(
                            learner?.initials ?? '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: context.assessmentColors.mathText,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                learner?.name ?? 'Learner',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: context.assessmentColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${learner?.className ?? 'Class'} • ${test?.title ?? 'Math Quick Check'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.assessmentColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.assessmentColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Text(
                            '$learnerIndex of $totalLearners',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: context.assessmentColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14),

                  // Timer Card
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isTimerRunning
                                  ? Icons.timer_outlined
                                  : Icons.timer_off_outlined,
                              color: _isTimerRunning
                                  ? green
                                  : context.assessmentColors.secondaryText,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              _formatDuration(_elapsedSeconds),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _isTimerRunning
                                    ? context.assessmentColors.text
                                    : context.assessmentColors.secondaryText,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _toggleTimer,
                          icon: Icon(
                            _isTimerRunning ? Icons.pause : Icons.play_arrow,
                            size: 18,
                            color: _isTimerRunning
                                ? context.assessmentColors.secondaryText
                                : green,
                          ),
                          label: Text(
                            _isTimerRunning ? 'Pause' : 'Resume',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _isTimerRunning
                                  ? context.assessmentColors.secondaryText
                                  : green,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isTimerRunning ? border : green,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Questions Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solve questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.assessmentColors.text,
                        ),
                      ),
                      Text(
                        '${questions.length} total',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.assessmentColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Questions List
                  if (questions.isEmpty)
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.assessmentColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Center(
                        child: Text(
                          'No questions configured for this test.',
                          style: TextStyle(
                            color: context.assessmentColors.secondaryText,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(questions.length, (i) {
                      final q = questions[i];
                      final recordedAnswer = _answers[i];
                      final isAnswered =
                          recordedAnswer != null &&
                          recordedAnswer.trim().isNotEmpty;
                      final isCorrect =
                          isAnswered &&
                          recordedAnswer.trim().toLowerCase() ==
                              q.answer.trim().toLowerCase();

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.assessmentColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isAnswered
                                ? border
                                : isCorrect
                                ? green.withValues(alpha: 0.6)
                                : context.assessmentColors.warningStroke
                                      .withValues(alpha: 0.6),
                            width: isAnswered ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'QUESTION ${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color:
                                        context.assessmentColors.secondaryText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.assessmentColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Expected: ${q.answer}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: context
                                          .assessmentColors
                                          .secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              q.prompt,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.assessmentColors.text,
                              ),
                            ),
                            SizedBox(height: 12),

                            // 1-Tap Evaluation Buttons: Correct vs Incorrect
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _markAnswer(i, q.answer),
                                    icon: Icon(Icons.check, size: 18),
                                    label: Text('Correct'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCorrect
                                          ? green
                                          : context.assessmentColors.background,
                                      foregroundColor: isCorrect
                                          ? Colors.white
                                          : context.assessmentColors.text,
                                      elevation: 0,
                                      side: BorderSide(
                                        color: isCorrect ? green : border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _markAnswer(i, 'incorrect'),
                                    icon: Icon(Icons.close, size: 18),
                                    label: Text('Incorrect'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          (isAnswered && !isCorrect)
                                          ? context
                                                .assessmentColors
                                                .warningStroke
                                          : context.assessmentColors.background,
                                      foregroundColor:
                                          (isAnswered && !isCorrect)
                                          ? Colors.white
                                          : context.assessmentColors.text,
                                      elevation: 0,
                                      side: BorderSide(
                                        color: (isAnswered && !isCorrect)
                                            ? context
                                                  .assessmentColors
                                                  .warningStroke
                                            : border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  SizedBox(height: 12),

                  // Score Summary & Auto Rubric Suggestion
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: context.assessmentColors.text,
                              ),
                            ),
                            Text(
                              '$correctCount / ${questions.length} (${percent.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        Text(
                          'RUBRIC LEVEL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.assessmentColors.secondaryText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 10),

                        // Rubric level 1-2-3 chips
                        Row(
                          children: ResponseLevel.values.map((lvl) {
                            final isSelected = activeLevel == lvl;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _manualLevel = lvl);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? green
                                          : context.assessmentColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? green : border,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${lvl.value}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isSelected
                                                ? Colors.white
                                                : context.assessmentColors.text,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          _levelName(lvl),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : context
                                                      .assessmentColors
                                                      .secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Skip learner option
                  Center(
                    child: TextButton(
                      onPressed: _skipLearner,
                      child: Text(
                        provider.hasNextLearner
                            ? 'Skip this learner'
                            : 'Skip & exit',
                        style: TextStyle(
                          color: context.assessmentColors.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Save & Next Button
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: context.assessmentColors.surface,
                border: Border(top: BorderSide(color: border)),
              ),
              child: SizedBox(
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
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          provider.hasNextLearner
                              ? 'Save & next student'
                              : 'Finish assessment',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _levelName(ResponseLevel level) => switch (level) {
    ResponseLevel.struggling => 'Struggling',
    ResponseLevel.developing => 'Developing',
    ResponseLevel.proficient => 'Proficient',
  };
}
