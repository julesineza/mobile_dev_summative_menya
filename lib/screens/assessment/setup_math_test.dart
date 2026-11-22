import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/assessment_colors.dart';
import '../../models/assessment_test.dart';
import '../../models/enums.dart';
import '../../models/school_class.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/class_provider.dart';

class _MathQuestionItem {
  final TextEditingController prompt;
  final TextEditingController answer;

  _MathQuestionItem({String p = '', String a = ''})
    : prompt = TextEditingController(text: p),
      answer = TextEditingController(text: a);

  void dispose() {
    prompt.dispose();
    answer.dispose();
  }
}

class TestSetupMathPage extends StatefulWidget {
  const TestSetupMathPage({super.key});

  @override
  State<TestSetupMathPage> createState() => _TestSetupMathPageState();
}

class _TestSetupMathPageState extends State<TestSetupMathPage> {
  late final TextEditingController _nameController;
  late String _selectedClass;
  bool _isSaving = false;

  final List<_MathQuestionItem> _questions = [
    _MathQuestionItem(p: '12 ÷ 3 = ?', a: '4'),
    _MathQuestionItem(p: '15 ÷ 5 = ?', a: '3'),
    _MathQuestionItem(p: '8 + 9 = ?', a: '17'),
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AssessmentProvider>();
    _selectedClass = provider.selectedClassName;
    _nameController = TextEditingController(
      text: '$_selectedClass · Math practice',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  int _parseGrade(String className) {
    if (className.contains('1')) return 1;
    if (className.contains('2')) return 2;
    return 3;
  }

  List<SchoolClass> get _classItems {
    final classes = context.watch<ClassProvider>().classes;
    if (classes.isNotEmpty) return classes;
    return const ['P1-A', 'P1-B', 'P2-A', 'P2-B', 'P3-A', 'P3-B']
        .map(
          (name) => SchoolClass(
            id: name,
            schoolId: '',
            teacherId: '',
            name: name,
            grade: _parseGrade(name),
          ),
        )
        .toList();
  }

  List<SchoolClass> get _dropdownClasses {
    final items = List<SchoolClass>.of(_classItems);
    final hasSelected = items.any((c) => c.name == _selectedClass);
    if (!hasSelected) {
      items.insert(
        0,
        SchoolClass(
          id: _selectedClass,
          schoolId: '',
          teacherId: '',
          name: _selectedClass,
          grade: _parseGrade(_selectedClass),
        ),
      );
    }
    return items;
  }

  Future<void> _saveTest() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter a test name.')));
      return;
    }

    final validQuestions = _questions
        .where(
          (q) =>
              q.prompt.text.trim().isNotEmpty &&
              q.answer.text.trim().isNotEmpty,
        )
        .map(
          (q) => TestQuestion(
            prompt: q.prompt.text.trim(),
            answer: q.answer.text.trim(),
          ),
        )
        .toList();

    if (validQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least one question and answer.'),
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
        grade: _parseGrade(_selectedClass),
        language: Language.english,
        questions: validQuestions,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Math test "${createdTest.title}" ready!'),
          backgroundColor: AppColors.button,
        ),
      );

      // Navigate directly to select learners with this new test
      context.pushReplacement(AppRoutes.selectLearners);
    } catch (error) {
      debugPrint('[SetupMath] save error: $error');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save test: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    final bg = context.assessmentColors.background;
    final border = context.assessmentColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
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
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Text(
                    'Set up a test',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: context.assessmentColors.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose what learners will read or solve.',
                    style: TextStyle(
                      fontSize: 15,
                      color: context.assessmentColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Segmented Subject Switcher
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.barBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.pushReplacement(AppRoutes.setupReading);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Soma · Reading',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: context.assessmentColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
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
                  SizedBox(height: 20),

                  // Test Name
                  Text(
                    'Test name',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: context.assessmentColors.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.assessmentColors.surface,
                      contentPadding: EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: green, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Class Selector Dropdown
                  Text(
                    'Target class',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: context.assessmentColors.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.assessmentColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClass,
                        isExpanded: true,
                        items: _dropdownClasses
                            .map(
                              (cls) => DropdownMenuItem(
                                value: cls.name,
                                child: Text(
                                  'Class ${cls.name}',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedClass = v;
                              _nameController.text =
                                  '$_selectedClass · Math practice';
                            });
                            SchoolClass? match;
                            for (final c in _dropdownClasses) {
                              if (c.name == v) {
                                match = c;
                                break;
                              }
                            }
                            if (match != null) {
                              context
                                  .read<AssessmentProvider>()
                                  .setSelectedClass(
                                    name: match.name,
                                    id: match.id,
                                    schoolId: match.schoolId,
                                  );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Questions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Math questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.assessmentColors.text,
                        ),
                      ),
                      Text(
                        '${_questions.length} questions',
                        style: TextStyle(
                          color: context.assessmentColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Question / Problem',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.assessmentColors.secondaryText,
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
                            color: context.assessmentColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 44),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Questions Form
                  ...List.generate(_questions.length, (i) {
                    final q = _questions[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: q.prompt,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: context.assessmentColors.surface,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                prefix: Text(
                                  '${i + 1}.  ',
                                  style: TextStyle(
                                    color:
                                        context.assessmentColors.secondaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: green,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: q.answer,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: context.assessmentColors.surface,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: green,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _questions.length > 1
                                ? () {
                                    setState(() {
                                      final removed = _questions.removeAt(i);
                                      removed.dispose();
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: _questions.length > 1
                                  ? context.assessmentColors.warningStroke
                                  : context.assessmentColors.border,
                              size: 22,
                            ),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _questions.add(_MathQuestionItem())),
                      icon: Icon(Icons.add, color: green, size: 20),
                      label: Text(
                        'Add question',
                        style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: context.assessmentColors.primarySoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: context.assessmentColors.primaryBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Save Button
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
                  onPressed: _isSaving ? null : _saveTest,
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
                          'Save & Select Learners',
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
}
