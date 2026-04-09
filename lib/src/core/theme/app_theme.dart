import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = AppPalette.lightScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.light().background,
      cardColor: scheme.surface,
      dividerColor: AppPalette.light().border,
      extensions: <ThemeExtension<dynamic>>[
        AppPalette.light(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.light().background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.light().backgroundAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.light().border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.light().border),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = AppPalette.darkScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.dark().background,
      cardColor: scheme.surface,
      dividerColor: AppPalette.dark().border,
      extensions: <ThemeExtension<dynamic>>[
        AppPalette.dark(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.dark().background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.dark().backgroundAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.dark().border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.dark().border),
        ),
      ),
    );
  }
}

