import 'package:flutter/material.dart';

class AppPalette {
  // Provided palette
  static const _lightPrimary = Color(0xFF2A3F6D);
  static const _lightPrimaryDark = Color(0xFF1E2430);
  static const _lightAccent = Color(0xFF6B8BBE);
  static const _lightBackground = Color(0xFFF6F5F1);
  static const _lightBackgroundAlt = Color(0xFFEFEDE6);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightBorder = Color(0xFFC9CED6);
  static const _lightText = Color(0xFF1E2430);
  static const _lightTextMuted = Color(0xFF4A5D73);
  static const _lightOnPrimary = Color(0xFFF6F5F1);

  static const _darkPrimary = Color(0xFF93C5FD);
  static const _darkPrimaryDark = Color(0xFFBFDBFE);
  static const _darkAccent = Color(0xFF60A5FA);
  static const _darkBackground = Color(0xFF1E293B);
  static const _darkBackgroundAlt = Color(0xFF334155);
  static const _darkSurface = Color(0xFF0F172A);
  static const _darkBorder = Color(0xFF475569);
  static const _darkText = Color(0xFFF8FAFC);
  static const _darkTextMuted = Color(0xFFCBD5E1);
  static const _darkOnPrimary = Color(0xFF1E293B);

  static ColorScheme lightScheme() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      secondary: _lightAccent,
      onSecondary: _lightOnPrimary,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: _lightSurface,
      onSurface: _lightText,
    );
  }

  static ColorScheme darkScheme() {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      secondary: _darkAccent,
      onSecondary: _darkOnPrimary,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
      surface: _darkSurface,
      onSurface: _darkText,
    );
  }

  static AppColors light() => const AppColors(
        primaryDark: _lightPrimaryDark,
        background: _lightBackground,
        backgroundAlt: _lightBackgroundAlt,
        border: _lightBorder,
        textMuted: _lightTextMuted,
      );

  static AppColors dark() => const AppColors(
        primaryDark: _darkPrimaryDark,
        background: _darkBackground,
        backgroundAlt: _darkBackgroundAlt,
        border: _darkBorder,
        textMuted: _darkTextMuted,
      );
}

class AppColors extends ThemeExtension<AppColors> {
  final Color primaryDark;
  final Color background;
  final Color backgroundAlt;
  final Color border;
  final Color textMuted;

  const AppColors({
    required this.primaryDark,
    required this.background,
    required this.backgroundAlt,
    required this.border,
    required this.textMuted,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? primaryDark,
    Color? background,
    Color? backgroundAlt,
    Color? border,
    Color? textMuted,
  }) {
    return AppColors(
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t) ?? primaryDark,
      background: Color.lerp(background, other.background, t) ?? background,
      backgroundAlt:
          Color.lerp(backgroundAlt, other.backgroundAlt, t) ?? backgroundAlt,
      border: Color.lerp(border, other.border, t) ?? border,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

