import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/school_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _school = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    context.read<SchoolProvider>().load();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    _school.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      schoolId: _school.value!,
    );
    if (!mounted) return;
    if (ok) {
      showAppSnackBar(
        context,
        'Account created. Check your email for the verification link, then sign in.',
      );
      context.go(AppRoutes.login);
    } else {
      showAppSnackBar(
        context,
        auth.errorMessage ?? 'Could not register.',
        isError: true,
      );
    }
  }

  Future<void> _google() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!ok && auth.errorMessage != null && mounted) {
      showAppSnackBar(context, auth.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: AuthLayout(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Full name',
                  hint: 'Jean Bosco',
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'School email',
                  hint: 'teacher@school.rw',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                SchoolPicker(selected: _school),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: '8+ characters, letters and numbers',
                  controller: _password,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Repeat password',
                  controller: _confirm,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Create account',
            onPressed: _submit,
            loading: loading,
          ),
          const SizedBox(height: 12),
          GoogleButton(onPressed: loading ? null : _google),
        ],
      ),
    );
  }
}
