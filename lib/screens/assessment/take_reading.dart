import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../providers/assessment_provider.dart';

class ReadingPausedPage extends StatefulWidget {
  const ReadingPausedPage({super.key});

  @override
  State<ReadingPausedPage> createState() => _ReadingPausedPageState();
}

class _ReadingPausedPageState extends State<ReadingPausedPage> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  final Set<int> _errorIndexes = {};
  bool _isPreparing = true;
  bool _isTimerRunning = true;
  Object? _preparationError;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final provider = context.read<AssessmentProvider>();
      if (provider.test == null) await provider.prepareAssessment();
      try {
        await provider.ensureSession();
      } on TimeoutException catch (error) {
        if (mounted) setState(() => _preparationError = error);
      }
    } catch (error) {
      if (mounted) setState(() => _preparationError = error);
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _isTimerRunning = false);
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

  void _toggleWord(int index) {
    setState(() {
      if (!_errorIndexes.add(index)) _errorIndexes.remove(index);
    });
  }

  List<String> _passageWords() {
    final provider = context.read<AssessmentProvider>();
    return (provider.test?.passageText ??
            'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.')
        .trim()
        .split(RegExp(r'\s+'));
  }

  void _finishReading() {
    _stopTimer();
    final provider = context.read<AssessmentProvider>();
    provider.setReadingCapture(
      errorWords: _errorIndexes.map((index) => _passageWords()[index]).toList(),
      durationSec: _elapsedSeconds,
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.assessReading);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final words = _passageWords();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Save & leave'),
                  ),
                  Text(
                    '${provider.learners.isEmpty ? 0 : provider.learners.indexOf(learner!) + 1} OF ${provider.learners.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            if (_preparationError != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to start this assessment: $_preparationError',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                children: [
                  Text(
                    'Reading assessment',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap a word each time the learner misreads it.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  if (learner != null)
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFD9EADF),
                          child: Text(learner.initials),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              learner.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${learner.className} · English reading'),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFFEAF3EC),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTimerRunning
                                    ? 'Timer running'
                                    : 'Timer stopped',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDuration(_elapsedSeconds),
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _isTimerRunning
                                ? _stopTimer
                                : _startTimer,
                            icon: Icon(
                              _isTimerRunning ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(
                              _isTimerRunning ? 'Stop timer' : 'Start timer',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 10,
                        children: [
                          for (var index = 0; index < words.length; index++)
                            GestureDetector(
                              onTap: () => _toggleWord(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _errorIndexes.contains(index)
                                      ? AppColors.warningFill
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _errorIndexes.contains(index)
                                          ? AppColors.warningStroke
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  words[index],
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _errorIndexes.contains(index)
                                        ? AppColors.warningStroke
                                        : AppColors.text,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${_errorIndexes.length} mistakes marked'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishReading,
                  child: Text(
                    _isTimerRunning ? 'Stop timer & review' : 'Finish & review',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
