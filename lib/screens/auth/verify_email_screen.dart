import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/primary_button.dart';

/// Shown to email/password users until they confirm their email address.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.firebaseUser?.email ?? '';

    return Scaffold(
      body: AuthLayout(
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Verify your email',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a verification link to $email. Open it, then come back and tap the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: "I've verified my email",
            loading: auth.isLoading,
            onPressed: () async {
              final verified = await auth.refreshVerification();
              if (!verified && context.mounted) {
                showAppSnackBar(
                  context,
                  'Your email is not verified yet. Check your inbox.',
                  isError: true,
                );
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final sent = await auth.resendVerification();
                    if (context.mounted) {
                      showAppSnackBar(
                        context,
                        sent
                            ? 'Verification email sent.'
                            : auth.errorMessage ?? 'Could not send the email.',
                        isError: !sent,
                      );
                    }
                  },
            child: const Text('Resend email'),
          ),
          TextButton(
            onPressed: auth.isLoading ? null : auth.signOut,
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
