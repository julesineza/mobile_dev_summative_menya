import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_palette.dart';

/// Centred, scrollable, width-limited container shared by the auth screens.
/// Scrolling keeps it overflow-free in landscape and on small phones.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Menya',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        Text(
          'Track learning. Support every learner.',
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
      ],
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Continue with Google',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}