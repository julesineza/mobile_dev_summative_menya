import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

class AppSpacing {
  AppSpacing._();
  static const radius = 14.0;
  static const screenPadding = EdgeInsets.symmetric(horizontal: 16);
}

/// Light and dark themes. Every member should build UI from these
/// (Theme.of(context) and context.palette) instead of hard-coding colours.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF14161C)
        : const Color(0xFFFBF6EA);
    final surface = isDark ? const Color(0xFF1E2129) : Colors.white;
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(primary: AppColors.primary, surface: surface);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [palette],
    );

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: palette.textHint, fontSize: 13),
        enabledBorder: border(palette.border),
        focusedBorder: border(AppColors.primary),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: palette.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.action
                : palette.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.action
                : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
