import 'package:flutter/material.dart';

/// App-wide color constants.
class AppColors {
  AppColors._();

  // Sidebar
  static const Color sidebarBg = Color(0xFF0D1B4B);
  static const Color sidebarSelected = Color(0xFF1E3A8A);
  static const Color sidebarAccent = Color(0xFF6C63FF);

  // Status colours
  static const Color present = Color(0xFF22C55E);
  static const Color absent = Color(0xFFEF4444);
  static const Color retard = Color(0xFFF59E0B);
  static const Color justifie = Color(0xFF3B82F6);

  // Filière chips
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color geiiPurple = Color(0xFF8B5CF6);
  static const Color dataTeal = Color(0xFF14B8A6);

  // Seed / primary
  static const Color seed = Color(0xFF1E40AF);
}

/// Material 3 theme configuration for light and dark modes.
class AppTheme {
  AppTheme._();

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    return _base(cs);
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    return _base(cs);
  }

  static ThemeData _base(ColorScheme cs) => ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor:
            cs.brightness == Brightness.light ? const Color(0xFFF8FAFC) : null,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: cs.brightness == Brightness.light
              ? Colors.white
              : cs.surfaceContainer,
          foregroundColor: cs.onSurface,
          titleTextStyle: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: cs.brightness == Brightness.light ? Colors.white : cs.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: cs.brightness == Brightness.light
                  ? const Color(0xFFE2E8F0)
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cs.brightness == Brightness.light
              ? const Color(0xFFF1F5F9)
              : cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.seed, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(space: 0, thickness: 1),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );
}
