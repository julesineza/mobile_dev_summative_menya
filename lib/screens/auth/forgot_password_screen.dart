import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    if (ok) {
      showAppSnackBar(
        context,
        'If an account exists for that email, a reset link is on its way.',
      );
      context.pop();
    } else {
      showAppSnackBar(
        context,
        auth.errorMessage ?? 'Could not send the link.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: AuthLayout(
        children: [
          Text(
            'Enter your school email and we will send you a link to reset your password.',
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: AppTextField(
              label: 'School email',
              hint: 'teacher@school.rw',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.email,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Send reset link',
            onPressed: _submit,
            loading: loading,
          ),
        ],
      ),
    );
  }
}
