import 'package:flutter/material.dart';

/// Brand colours that stay the same in light and dark mode.
/// Mode-dependent colours live in [AppPalette].
class AppColors {
  AppColors._();

  /// Slightly darker than the Figma orange so white text meets 4.5:1 contrast.
  static const primary = Color(0xFFC9532A);
  static const action = Color(0xFF2F6BFF);
  static const success = Color(0xFF2E7D4F);
  static const danger = Color(0xFFD9473A);
}
