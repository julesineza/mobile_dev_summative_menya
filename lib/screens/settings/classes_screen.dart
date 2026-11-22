import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/view_state.dart';
import '../../models/school_class.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/app_snackbar.dart';
import 'class_form_dialog.dart';

/// "My classes": the teacher's classes with create, edit and delete.
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  Future<void> _delete(BuildContext context, SchoolClass schoolClass) async {
    final classes = context.read<ClassProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('Delete ${schoolClass.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await classes.deleteClass(schoolClass);
    if (context.mounted) {
      showAppSnackBar(
        context,
        ok ? 'Class deleted' : classes.errorMessage ?? 'Could not delete.',
        isError: !ok,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassProvider>();
    final schoolId = context.watch<AuthProvider>().profile?.schoolId ?? '';
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('My classes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: schoolId.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => ClassFormDialog(schoolId: schoolId),
              ),
        icon: const Icon(Icons.add),
        label: const Text('Add class'),
      ),
      body: Builder(
        builder: (context) {
          if (classes.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classes.classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No classes yet. Tap "Add class" to create one, for example P3-A.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: classes.classes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final schoolClass = classes.classes[index];
              final isSelected = classes.selectedClass?.id == schoolClass.id;
              return Card(
                child: ListTile(
                  title: Text(
                    schoolClass.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Grade P${schoolClass.grade}'
                    '${schoolClass.academicYear == null ? '' : ' · ${schoolClass.academicYear}'}'
                    '${isSelected ? ' · Selected' : ''}',
                  ),
                  onTap: () => classes.select(schoolClass.id),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'students') {
                        context.push(
                          '${AppRoutes.settings}/classes/${schoolClass.id}/students',
                          extra: schoolClass,
                        );
                      } else if (action == 'edit') {
                        showDialog<void>(
                          context: context,
                          builder: (_) => ClassFormDialog(
                            schoolId: schoolClass.schoolId,
                            existing: schoolClass,
                          ),
                        );
                      } else {
                        _delete(context, schoolClass);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'students', child: Text('Students')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
