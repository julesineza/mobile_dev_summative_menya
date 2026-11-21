import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../models/enums.dart';
import '../../providers/assessment_provider.dart';

class TestSetupReadingPage extends StatefulWidget {
  const TestSetupReadingPage({super.key});

  @override
  State<TestSetupReadingPage> createState() => _TestSetupReadingPageState();
}

class _TestSetupReadingPageState extends State<TestSetupReadingPage> {
  final testNameController = TextEditingController(text: 'P3 · Reading words');
  final wordsController = TextEditingController(
    text: 'school, books, story, brother, carry, mango, tree, walk, read, together',
  );

  String selectedClass = 'P3-A';
  String selectedLanguage = 'English';
  String contentType = 'Word list'; // Word list | Passage
  String timerMode = 'Count up'; // Count up | 60 sec | Custom
  bool _isSaving = false;

  int get wordCount {
    final text = wordsController.text.trim();
    if (text.isEmpty) return 0;
    if (contentType == 'Word list') {
      return text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .length;
    } else {
      return text
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .length;
    }
  }

  @override
  void dispose() {
    testNameController.dispose();
    wordsController.dispose();
    super.dispose();
  }

  int _parseGrade(String className) {
    if (className.contains('1')) return 1;
    if (className.contains('2')) return 2;
    return 3;
  }

  Language _parseLanguage(String lang) {
    switch (lang.toLowerCase()) {
      case 'kinyarwanda':
        return Language.kinyarwanda;
      case 'french':
        return Language.french;
      default:
        return Language.english;
    }
  }

  String _buildPassageText() {
    final raw = wordsController.text.trim();
    if (contentType == 'Word list') {
      final words = raw
          .split(',')
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .toList();
      return words.join(' ');
    }
    return raw;
  }

  Future<void> _saveTest() async {
    final title = testNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test name.')),
      );
      return;
    }

    final passage = _buildPassageText();
    if (passage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide words or a passage to read.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AssessmentProvider>();
      final createdTest = await provider.saveCustomTest(
        title: title,
        subject: Subject.reading,
        grade: _parseGrade(selectedClass),
        language: _parseLanguage(selectedLanguage),
        passageText: passage,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test "${createdTest.title}" saved successfully!'),
          backgroundColor: AppColors.button,
        ),
      );

      // Offer prompt to start assessment immediately or stay
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Test Saved', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            'Test "${createdTest.title}" is ready. Would you like to select learners and start assessing now?',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Return to previous page
              },
              child: const Text('Done', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.selectLearners);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start test now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('[SetupReading] save error: $error');
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
            // Top Bar
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

                  // Subject toggle
                  _segmented(
                    left: 'Soma · Reading',
                    right: 'Imibare · Math',
                    selectedLeft: true,
                    onTapLeft: () {},
                    onTapRight: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.setupMath);
                    },
                  ),
                  const SizedBox(height: 20),

                  _label('Test name'),
                  _textField(testNameController, border),
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
                            _label('Language'),
                            _dropdown(
                              selectedLanguage,
                              ['English', 'Kinyarwanda', 'French'],
                              (v) => setState(() => selectedLanguage = v!),
                              border,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Reading content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _segmented(
                    left: 'Word list',
                    right: 'Passage',
                    selectedLeft: contentType == 'Word list',
                    onTapLeft: () {
                      if (contentType != 'Word list') {
                        setState(() {
                          contentType = 'Word list';
                          if (wordsController.text.trim().isEmpty) {
                            wordsController.text = 'school, books, story, brother, carry, mango, tree, walk, read, together';
                          }
                        });
                      }
                    },
                    onTapRight: () {
                      if (contentType != 'Passage') {
                        setState(() {
                          contentType = 'Passage';
                          if (wordsController.text.contains(',')) {
                            wordsController.text = 'Amina walks to school with her brother. They carry books and read a story together under the big mango tree.';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  _label(contentType == 'Word list' ? 'Words to read' : 'Passage to read'),
                  TextField(
                    controller: wordsController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: contentType == 'Word list'
                          ? 'Enter words separated by commas...'
                          : 'Enter passage sentences for pupils to read aloud...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: green, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contentType == 'Word list'
                        ? '$wordCount words · Separate words with commas.'
                        : '$wordCount words in passage.',
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Timer Card
                  _timerCard(
                    title: 'Per reading',
                    options: const ['Count up', '60 sec', 'Custom'],
                    selected: timerMode,
                    onSelect: (v) => setState(() => timerMode = v),
                    border: border,
                    green: green,
                  ),
                  const SizedBox(height: 24),

                  // Save Button
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
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
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

  Widget _textField(TextEditingController c, Color border) => TextField(
        controller: c,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.button, width: 1.5),
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
            icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.secondaryText),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _segmented({
    required String left,
    required String right,
    required bool selectedLeft,
    required VoidCallback onTapLeft,
    required VoidCallback onTapRight,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.barBorder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _segmentButton(left, selectedLeft, onTapLeft)),
          Expanded(child: _segmentButton(right, !selectedLeft, onTapRight)),
        ],
      ),
    );
  }

  Widget _segmentButton(String text, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.button : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? Colors.white : AppColors.secondaryText,
            ),
          ),
        ),
      );

  Widget _timerCard({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    required Color border,
    required Color green,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Timer',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
              ),
              Text(title, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((o) {
              final isSel = o == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(o),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? green : AppColors.background,
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
                        color: isSel ? Colors.white : AppColors.text,
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
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
