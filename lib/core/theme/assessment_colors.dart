import 'package:flutter/material.dart';

/// Theme-aware colours for the assessment flow.
///
/// Assessment screens were originally built with the light-only constants in
/// `core/constants/colors.dart`. This keeps the same light appearance while
/// providing readable dark-mode equivalents.
class AssessmentColors {
  const AssessmentColors._({
    required this.text,
    required this.background,
    required this.surface,
    required this.secondaryText,
    required this.hint,
    required this.border,
    required this.divider,
    required this.barBorder,
    required this.primarySoft,
    required this.primaryBorder,
    required this.warningFill,
    required this.warningStroke,
    required this.amberSoft,
    required this.amberText,
    required this.mathSoft,
    required this.mathText,
    required this.instructionBg,
    required this.instructionText,
  });

  final Color text;
  final Color background;
  final Color surface;
  final Color secondaryText;
  final Color hint;
  final Color border;
  final Color divider;
  final Color barBorder;
  final Color primarySoft;
  final Color primaryBorder;
  final Color warningFill;
  final Color warningStroke;
  final Color amberSoft;
  final Color amberText;
  final Color mathSoft;
  final Color mathText;
  final Color instructionBg;
  final Color instructionText;

  static AssessmentColors of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AssessmentColors._(
      text: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1C1F22),
      background: theme.scaffoldBackgroundColor,
      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      secondaryText: isDark ? const Color(0xFFA6ADBB) : const Color(0xFF6B7075),
      hint: isDark ? const Color(0xFF8A91A0) : const Color(0xFF757575),
      border: isDark ? const Color(0xFF2E3340) : const Color(0xFFE9E5DE),
      divider: isDark ? const Color(0xFF3A3F4A) : const Color(0xFFDADBD4),
      barBorder: isDark ? const Color(0xFF2E3340) : const Color(0xFFE3E1DB),
      primarySoft: isDark ? const Color(0xFF1E3527) : const Color(0xFFEAF4EC),
      primaryBorder: isDark ? const Color(0xFF3E5C48) : const Color(0xFFB8CEBD),
      warningFill: isDark ? const Color(0xFF3A2422) : const Color(0xFFFDEDEC),
      warningStroke: isDark ? const Color(0xFFFF8A80) : const Color(0xFFC0392B),
      amberSoft: isDark ? const Color(0xFF3A2E14) : const Color(0xFFFFF3CD),
      amberText: isDark ? const Color(0xFFF2C66D) : const Color(0xFF856404),
      mathSoft: isDark ? const Color(0xFF3A2417) : const Color(0xFFFFF1E7),
      mathText: isDark ? const Color(0xFFFFB38A) : const Color(0xFFFF6500),
      instructionBg: isDark ? const Color(0xFF1E3527) : const Color(0xFFF0F5F1),
      instructionText: isDark
          ? const Color(0xFFD7E8DC)
          : const Color(0xFF334036),
    );
  }
}

extension AssessmentColorsContext on BuildContext {
  AssessmentColors get assessmentColors => AssessmentColors.of(this);
}
