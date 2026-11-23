import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/school_class.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_text_field.dart';

/// Adds a student to [schoolClass] in the Firestore `students` collection.
class StudentFormDialog extends StatefulWidget {
  const StudentFormDialog({
    super.key,
    required this.schoolClass,
    required this.schoolId,
  });

  final SchoolClass schoolClass;
  final String schoolId;

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _rollNo = TextEditingController();
  final _saving = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _name.dispose();
    _rollNo.dispose();
    _saving.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final students = context.read<StudentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    _saving.value = true;
    final ok = await students.addStudent(
      schoolId: widget.schoolId,
      classId: widget.schoolClass.id,
      name: _name.text.trim(),
      rollNo: int.parse(_rollNo.text.trim()),
    );
    _saving.value = false;

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Student added')));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(students.errorMessage ?? 'Could not add student.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add student to ${widget.schoolClass.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full name',
                hint: 'Aline Uwase',
                controller: _name,
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Roll number',
                hint: '7',
                controller: _rollNo,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final error = Validators.required(v, field: 'Roll number');
                  if (error != null) return error;
                  final n = int.tryParse(v!.trim());
                  if (n == null || n < 1) return 'Enter a number of 1 or more';
                  return null;
                },
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
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}
