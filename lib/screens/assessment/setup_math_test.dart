import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../models/assessment_test.dart';
import '../../models/enums.dart';
import '../../providers/assessment_provider.dart';

class MathQuestion {
  final TextEditingController question;
  final TextEditingController answer;

  MathQuestion({required String q, required String a})
      : question = TextEditingController(text: q),
        answer = TextEditingController(text: a);

  void dispose() {
    question.dispose();
    answer.dispose();
  }
}

class TestSetupMathPage extends StatefulWidget {
  const TestSetupMathPage({super.key});

  @override
  State<TestSetupMathPage> createState() => _TestSetupMathPageState();
}

class _TestSetupMathPageState extends State<TestSetupMathPage> {
  final testNameController =
      TextEditingController(text: 'P3 · Division practice');
  String selectedClass = 'P3-A';
  String selectedLevel = 'Level 1';
  String timerMode = 'No limit'; // No limit | Count up | 60 sec
  bool _isSaving = false;

  final List<MathQuestion> questions = [
    MathQuestion(q: '12 ÷ 3 = ?', a: '4'),
    MathQuestion(q: '15 ÷ 5 = ?', a: '3'),
    MathQuestion(q: '8 + 9 = ?', a: '17'),
  ];

  @override
  void dispose() {
    testNameController.dispose();
    for (final q in questions) {
      q.dispose();
    }
    super.dispose();
  }

  int _parseGrade(String className) {
    if (className.contains('1')) return 1;
    if (className.contains('2')) return 2;
    return 3;
  }

  Future<void> _saveTest() async {
    final title = testNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test name.')),
      );
      return;
    }

    final validQuestions = questions
        .where(
          (q) =>
              q.question.text.trim().isNotEmpty &&
              q.answer.text.trim().isNotEmpty,
        )
        .map(
          (q) => TestQuestion(
            prompt: q.question.text.trim(),
            answer: q.answer.text.trim(),
          ),
        )
        .toList();

    if (validQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least one complete math question.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AssessmentProvider>();
      final createdTest = await provider.saveCustomTest(
        title: title,
        subject: Subject.math,
        grade: _parseGrade(selectedClass),
        language: Language.english,
        questions: validQuestions,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Math test "${createdTest.title}" saved successfully!'),
          backgroundColor: AppColors.button,
        ),
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Test Saved',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            'Math test "${createdTest.title}" with ${validQuestions.length} questions is ready. Would you like to select learners and start assessing now?',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done',
                  style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                    context, AppRoutes.selectLearners);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start test now',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('[SetupMath] save error: $error');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save test: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    const bg = AppColors.background;
    const border = AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
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
                            fontSize: 16,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  const Text(
                    'Set up a test',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose what learners will read or solve.',
                    style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 20),

                  // Subject toggle - Math selected
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.barBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .pushReplacementNamed(AppRoutes.setupReading);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Soma · Reading',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Imibare · Math',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _label('Test name'),
                  TextField(
                    controller: testNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: border),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: green, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Class'),
                            _dropdown(
                              selectedClass,
                              ['P3-A', 'P3-B', 'P2-A', 'P1-A'],
                              (v) => setState(() => selectedClass = v!),
                              border,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Level'),
                            _dropdown(
                              selectedLevel,
                              ['Level 1', 'Level 2', 'Level 3'],
                              (v) => setState(() => selectedLevel = v!),
                              border,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Math questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        '${questions.length} questions',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Question / Prompt',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Answer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Questions list
                  ...List.generate(questions.length, (i) {
                    final q = questions[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: q.question,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                prefix: Text(
                                  '${i + 1}.  ',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: border),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: green, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: q.answer,
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: border),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: green, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: questions.length > 1
                                ? () {
                                    setState(() {
                                      final removed = questions.removeAt(i);
                                      removed.dispose();
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: questions.length > 1
                                  ? AppColors.warningStroke
                                  : Colors.grey.shade300,
                              size: 22,
                            ),
                            tooltip: 'Remove question',
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () => setState(
                        () => questions.add(MathQuestion(q: '', a: '')),
                      ),
                      icon: const Icon(Icons.add, color: green, size: 20),
                      label: const Text(
                        'Add question',
                        style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.primaryBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Timer Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Timer',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'Per learner',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children:
                              ['No limit', 'Count up', '60 sec'].map((o) {
                            final isSel = o == timerMode;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => timerMode = o),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color:
                                        isSel ? green : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? green : border,
                                    ),
                                  ),
                                  child: Text(
                                    o,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color:
                                          isSel ? Colors.white : AppColors.text,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Rubric: 1 Struggling · 2 Developing · 3 Proficient',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTest,
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
                          : const Text(
                              'Save test',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Saved tests are available when starting a check.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.text,
          ),
        ),
      );

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    Color border,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.secondaryText,
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
