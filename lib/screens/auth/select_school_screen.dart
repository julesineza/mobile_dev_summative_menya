import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/school_picker.dart';

/// Google users have no school yet, so they pick one before using the app.
class SelectSchoolScreen extends StatefulWidget {
  const SelectSchoolScreen({super.key});

  @override
  State<SelectSchoolScreen> createState() => _SelectSchoolScreenState();
}

class _SelectSchoolScreenState extends State<SelectSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _school = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    context.read<SchoolProvider>().load();
  }

  @override
  void dispose() {
    _school.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(schoolId: _school.value);
    if (!ok && mounted) {
      showAppSnackBar(
        context,
        auth.errorMessage ?? 'Could not save.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return Scaffold(
      body: AuthLayout(
        children: [
          const Text(
            'One last step',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the school where you teach.',
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: SchoolPicker(selected: _school),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Continue', onPressed: _save, loading: loading),
          TextButton(
            onPressed: loading
                ? null
                : () => context.read<AuthProvider>().signOut(),
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
