import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();
  late final ValueNotifier<bool> _rememberEmail;

  @override
  void initState() {
    super.initState();
    // Pre-fill the email saved in SharedPreferences (if the user chose that).
    final saved = context.read<SettingsProvider>().rememberedEmail;
    _email = TextEditingController(text: saved);
    _rememberEmail = ValueNotifier(saved.isNotEmpty);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _rememberEmail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final email = _email.text.trim();

    final ok = await auth.signInWithEmail(email, _password.text);
    if (ok) {
      await settings.setRememberedEmail(_rememberEmail.value ? email : '');
    } else if (mounted) {
      showAppSnackBar(
        context,
        auth.errorMessage ?? 'Sign in failed.',
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
      body: AuthLayout(
        children: [
          const BrandHeader(),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'School email',
                  hint: 'teacher@school.rw',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v, field: 'Password'),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _rememberEmail,
                builder: (context, value, _) => Checkbox(
                  value: value,
                  onChanged: (v) => _rememberEmail.value = v ?? false,
                ),
              ),
              const Expanded(child: Text('Remember my email')),
              TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Sign In', onPressed: _submit, loading: loading),
          const SizedBox(height: 12),
          GoogleButton(onPressed: loading ? null : _google),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('New teacher? '),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text(
                  'Create an account',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
