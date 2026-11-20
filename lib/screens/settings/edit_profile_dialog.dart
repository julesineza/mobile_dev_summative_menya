import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/school_picker.dart';

/// UPDATE for users/{uid}: name and school.
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.profile});
  final AppUser profile;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final ValueNotifier<String?> _school;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _school = ValueNotifier(
      widget.profile.schoolId.isEmpty ? null : widget.profile.schoolId,
    );
    context.read<SchoolProvider>().load();
  }

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await auth.updateProfile(
      name: _name.text.trim(),
      schoolId: _school.value,
    );
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not update.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<AuthProvider, bool>((a) => a.isLoading);
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full name',
                hint: 'Jean Bosco',
                controller: _name,
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              SchoolPicker(selected: _school),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
