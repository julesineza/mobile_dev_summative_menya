import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/school_class.dart';
import '../../providers/class_provider.dart';
import '../../widgets/app_text_field.dart';

/// Create a class, or edit [existing].
class ClassFormDialog extends StatefulWidget {
  const ClassFormDialog({super.key, required this.schoolId, this.existing});

  final String schoolId;
  final SchoolClass? existing;

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _year;
  late final ValueNotifier<int> _grade;
  final _saving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _year = TextEditingController(
      text: c?.academicYear ?? DateTime.now().year.toString(),
    );
    _grade = ValueNotifier(c?.grade ?? 3);
  }

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    _grade.dispose();
    _saving.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final classes = context.read<ClassProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    _saving.value = true;
    final ok = await classes.saveClass(
      existing: widget.existing,
      schoolId: widget.schoolId,
      name: _name.text.trim(),
      grade: _grade.value,
      academicYear: _year.text.trim().isEmpty ? null : _year.text.trim(),
    );
    _saving.value = false;

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null ? 'Class added' : 'Class updated',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(classes.errorMessage ?? 'Could not save.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add class' : 'Edit class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Class name',
                hint: 'P3-A',
                controller: _name,
                validator: (v) => Validators.required(v, field: 'Class name'),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: FieldLabel('Grade'),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<int>(
                valueListenable: _grade,
                builder: (context, grade, _) => Wrap(
                  spacing: 8,
                  children: [
                    for (var g = 1; g <= 6; g++)
                      ChoiceChip(
                        label: Text('P$g'),
                        selected: grade == g,
                        onSelected: (_) => _grade.value = g,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Academic year',
                hint: '2026',
                controller: _year,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _saving,
          builder: (context, saving, _) => FilledButton(
            onPressed: saving ? null : _save,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
