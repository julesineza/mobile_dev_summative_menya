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
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initSession();
  }

  Future<void> _initSession() async {
    final provider = context.read<AssessmentProvider>();
    if (provider.test == null) await provider.prepareAssessment();
    await provider.ensureSession();
  }

  void _startTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _pauseTimer() {
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
      if (!_errorIndexes.add(index)) {
        _errorIndexes.remove(index);
      }
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
    _pauseTimer();
    final provider = context.read<AssessmentProvider>();
    final words = _passageWords();
    provider.setReadingCapture(
      errorWords: _errorIndexes.map((index) => words[index]).toList(),
      durationSec: _elapsedSeconds,
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.assessReading);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final learner = provider.currentLearner;
    final words = _passageWords();
    const green = AppColors.button;
    final learnerIndex = provider.currentLearnerIndex + 1;
    final totalLearners = provider.totalLearners;

    final wordCount = words.length;
    final errors = _errorIndexes.length;
    final correctWords = (wordCount - errors).clamp(0, wordCount);
    final accuracyPercent = wordCount > 0 ? (correctWords / wordCount * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _pauseTimer();
                      Navigator.pop(context);
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left, color: green, size: 20),
                        Text(
                          'Save & leave',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LEARNER $learnerIndex OF $totalLearners',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '3 OF 6',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // Learner Info Card
                  if (learner != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
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
                                  learner.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${learner.className} • English reading',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Timer Card (Active / Paused State)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _isTimerRunning ? AppColors.primarySoft : AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isTimerRunning ? AppColors.primaryBorder : const Color(0xFFFFD54F),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isTimerRunning ? Icons.circle : Icons.pause_circle_filled,
                                  size: 13,
                                  color: _isTimerRunning ? green : AppColors.amberText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isTimerRunning ? 'TIMER RUNNING' : 'TIMER PAUSED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _isTimerRunning ? green : AppColors.amberText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(_elapsedSeconds),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        // Pause / Resume Toggle Button
                        ElevatedButton.icon(
                          onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _isTimerRunning ? Icons.pause : Icons.play_arrow,
                            size: 18,
                            color: _isTimerRunning ? green : Colors.white,
                          ),
                          label: Text(
                            _isTimerRunning ? 'Pause' : 'Resume',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _isTimerRunning ? green : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTimerRunning ? Colors.white : green,
                            elevation: 0,
                            side: BorderSide(
                              color: _isTimerRunning ? AppColors.primaryBorder : green,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Paused helper banner
                  if (!_isTimerRunning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.amberText),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Test is paused. Tap "Resume" when learner continues.',
                              style: TextStyle(fontSize: 12, color: AppColors.amberText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Instruction label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TAP MISTAKES IN REAL TIME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'Tap word to toggle error',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Interactive Word-Tapping Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (var index = 0; index < words.length; index++)
                          GestureDetector(
                            onTap: () => _toggleWord(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _errorIndexes.contains(index)
                                    ? AppColors.warningFill
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _errorIndexes.contains(index)
                                      ? AppColors.warningStroke
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                words[index],
                                style: TextStyle(
                                  fontSize: 21,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                  color: _errorIndexes.contains(index)
                                      ? AppColors.warningStroke
                                      : AppColors.text,
                                  decoration: _errorIndexes.contains(index)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: AppColors.warningStroke,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Real-time live score card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$errors',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: errors > 0 ? AppColors.warningStroke : green,
                              ),
                            ),
                            const Text(
                              'Mistakes',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: AppColors.divider),
                        Column(
                          children: [
                            Text(
                              '${accuracyPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            const Text(
                              'Accuracy',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: AppColors.divider),
                        Column(
                          children: [
                            Text(
                              '$correctWords / $wordCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: green,
                              ),
                            ),
                            const Text(
                              'Words correct',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Finish & Review button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _finishReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isTimerRunning ? 'Stop timer & review' : 'Finish & review',
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
            ),
          ],
        ),
      ),
    );
  }
}
