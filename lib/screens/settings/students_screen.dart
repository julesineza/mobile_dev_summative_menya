import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../models/school_class.dart';
import '../../models/student.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/student_widgets.dart';
import 'student_form_dialog.dart';

/// Lists the students of one class and lets the teacher add or remove them.
class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  Future<void> _delete(BuildContext context, Student student) async {
    final students = context.read<StudentProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('Remove ${student.name} from ${schoolClass.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await students.deleteStudent(student.id);
    if (context.mounted) {
      showAppSnackBar(
        context,
        ok ? 'Student removed' : students.errorMessage ?? 'Could not remove.',
        isError: !ok,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>();
    final schoolId = context.watch<AuthProvider>().profile?.schoolId ?? '';
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text('Students · ${schoolClass.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: schoolId.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => StudentFormDialog(
                  schoolClass: schoolClass,
                  schoolId: schoolId,
                ),
              ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add student'),
      ),
      body: Column(
        children: [
          if (students.syncError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SyncErrorBanner(
                message: students.syncError,
                onDismiss: students.clearSyncError,
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (students.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (students.students.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No students yet. Tap "Add student" to add the first one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: students.students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = students.students[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${student.rollNo}')),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Roll ${student.rollNo} · ${student.status.name}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove student',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(context, student),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
