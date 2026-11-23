import 'package:flutter/material.dart';

/// Brand colours that stay the same in light and dark mode.
/// Mode-dependent colours live in [AppPalette].
/// Values are estimated from the Figma; replace them with the exact hex codes
/// from Figma's Design panel if they differ.
class AppColors {
  AppColors._();

  /// Figma orange: logo tile, Sign In button, links, chips.
  static const primary = Color(0xFFF58A5B);

  /// Deeper orange (about 4.7:1 with white). Switch buttons to this if you
  /// need to meet the 4.5:1 contrast rule.
  static const primaryStrong = Color(0xFFC24F27);

  /// Blue "Start a quick check" card and active bottom-nav item.
  static const action = Color(0xFF2F6BFF);

  /// Dark green "Start Quick Check Now" / "Save & next" buttons.
  static const success = Color(0xFF2E6B3F);

  static const danger = Color(0xFFD9473A);
}
