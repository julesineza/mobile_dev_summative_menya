import 'package:flutter/material.dart';

/// Colours that change between light and dark mode.
/// Read them with `context.palette` so widgets never hard-code text colours.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.border,
    required this.textSecondary,
    required this.textHint,
    required this.onTrackBg,
    required this.onTrackText,
    required this.needsSupportBg,
    required this.needsSupportText,
    required this.watchText,
  });

  final Color border;
  final Color textSecondary;
  final Color textHint;
  final Color onTrackBg;
  final Color onTrackText;
  final Color needsSupportBg;
  final Color needsSupportText;
  final Color watchText;

  static const light = AppPalette(
    border: Color(0xFFEDE4D3),
    textSecondary: Color(0xFF5B6270),
    textHint: Color(0xFF7A8190),
    onTrackBg: Color(0xFFE3EEFF),
    onTrackText: Color(0xFF1F54D6),
    needsSupportBg: Color(0xFFFFE6DA),
    needsSupportText: Color(0xFFB2431A),
    watchText: Color(0xFF9A6200),
  );

  static const dark = AppPalette(
    border: Color(0xFF2E3340),
    textSecondary: Color(0xFFA6ADBB),
    textHint: Color(0xFF8A91A0),
    onTrackBg: Color(0xFF1E2A4A),
    onTrackText: Color(0xFF8FB0FF),
    needsSupportBg: Color(0xFF3A2219),
    needsSupportText: Color(0xFFFFA283),
    watchText: Color(0xFFF2A33A),
  );

  @override
  AppPalette copyWith({
    Color? border,
    Color? textSecondary,
    Color? textHint,
    Color? onTrackBg,
    Color? onTrackText,
    Color? needsSupportBg,
    Color? needsSupportText,
    Color? watchText,
  }) {
    return AppPalette(
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      onTrackBg: onTrackBg ?? this.onTrackBg,
      onTrackText: onTrackText ?? this.onTrackText,
      needsSupportBg: needsSupportBg ?? this.needsSupportBg,
      needsSupportText: needsSupportText ?? this.needsSupportText,
      watchText: watchText ?? this.watchText,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      onTrackBg: Color.lerp(onTrackBg, other.onTrackBg, t)!,
      onTrackText: Color.lerp(onTrackText, other.onTrackText, t)!,
      needsSupportBg: Color.lerp(needsSupportBg, other.needsSupportBg, t)!,
      needsSupportText: Color.lerp(
        needsSupportText,
        other.needsSupportText,
        t,
      )!,
      watchText: Color.lerp(watchText, other.watchText, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
