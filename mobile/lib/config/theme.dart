// ============================================
// TEMA Y COLORES DE UNIPLAN
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta de colores dependiente de brillo (claro/oscuro). Los widgets NO
// deben leer `AppTheme.<color>` directamente (eso fija el color claro sin
// importar el tema activo) — deben usar `context.colors.<color>`, que
// resuelve al `AppColors` registrado en el `ThemeData` actual.
class AppColors extends ThemeExtension<AppColors> {
  final Color primaryGreen;
  final Color lightGreen;
  final Color darkText;
  final Color greyText;
  final Color white;
  final Color lightGrey;
  final Color borderGrey;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color surface;
  final Color surfaceContainerHighest;
  final Color primaryContainer;
  final Color tertiaryContainer;
  final Color outline;
  final Color outlineVariant;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color errorContainer;
  final Color primaryFixed;
  final Color secondaryFixed;
  final Color tertiaryFixed;
  final Color onSurfaceVariant;

  const AppColors({
    required this.primaryGreen,
    required this.lightGreen,
    required this.darkText,
    required this.greyText,
    required this.white,
    required this.lightGrey,
    required this.borderGrey,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.primaryContainer,
    required this.tertiaryContainer,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.errorContainer,
    required this.primaryFixed,
    required this.secondaryFixed,
    required this.tertiaryFixed,
    required this.onSurfaceVariant,
  });

  @override
  AppColors copyWith({
    Color? primaryGreen,
    Color? lightGreen,
    Color? darkText,
    Color? greyText,
    Color? white,
    Color? lightGrey,
    Color? borderGrey,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? surface,
    Color? surfaceContainerHighest,
    Color? primaryContainer,
    Color? tertiaryContainer,
    Color? outline,
    Color? outlineVariant,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? errorContainer,
    Color? primaryFixed,
    Color? secondaryFixed,
    Color? tertiaryFixed,
    Color? onSurfaceVariant,
  }) {
    return AppColors(
      primaryGreen: primaryGreen ?? this.primaryGreen,
      lightGreen: lightGreen ?? this.lightGreen,
      darkText: darkText ?? this.darkText,
      greyText: greyText ?? this.greyText,
      white: white ?? this.white,
      lightGrey: lightGrey ?? this.lightGrey,
      borderGrey: borderGrey ?? this.borderGrey,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      surface: surface ?? this.surface,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      errorContainer: errorContainer ?? this.errorContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t)!,
      lightGreen: Color.lerp(lightGreen, other.lightGreen, t)!,
      darkText: Color.lerp(darkText, other.darkText, t)!,
      greyText: Color.lerp(greyText, other.greyText, t)!,
      white: Color.lerp(white, other.white, t)!,
      lightGrey: Color.lerp(lightGrey, other.lightGrey, t)!,
      borderGrey: Color.lerp(borderGrey, other.borderGrey, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainerHighest: Color.lerp(
          surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      tertiaryContainer:
          Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
    );
  }
}

// Acceso corto: `context.colors.primaryGreen` en vez de
// `Theme.of(context).extension<AppColors>()!.primaryGreen`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  // ========== PALETA CLARA ==========
  static const Color primaryGreen = Color(0xFF00D9A0);
  static const Color lightGreen = Color(0xFFE0F9F4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color surface = Color(0xFFFAFBFC);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E1);
  static const Color primaryContainer = Color(0xFFA8F0DD);
  static const Color tertiaryContainer = Color(0xFFF5E6F7);
  static const Color outline = Color(0xFF747775);
  static const Color outlineVariant = Color(0xFFC4C7C5);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFEAEAEA);
  static const Color errorContainer = Color(0xFFF9DEDC);

  // "Fixed" (M3): por diseño se mantienen iguales en claro/oscuro.
  static const Color primaryFixed = Color(0xFFB8F0DD);
  static const Color secondaryFixed = Color(0xFFD6E5F5);
  static const Color tertiaryFixed = Color(0xFFF5E6F7);
  static const Color onSurfaceVariant = Color(0xFF404944);

  static const AppColors lightColors = AppColors(
    primaryGreen: primaryGreen,
    lightGreen: lightGreen,
    darkText: darkText,
    greyText: greyText,
    white: white,
    lightGrey: lightGrey,
    borderGrey: borderGrey,
    success: success,
    error: error,
    warning: warning,
    info: info,
    surface: surface,
    surfaceContainerHighest: surfaceContainerHighest,
    primaryContainer: primaryContainer,
    tertiaryContainer: tertiaryContainer,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    errorContainer: errorContainer,
    primaryFixed: primaryFixed,
    secondaryFixed: secondaryFixed,
    tertiaryFixed: tertiaryFixed,
    onSurfaceVariant: onSurfaceVariant,
  );

  // ========== PALETA OSCURA ==========
  static const Color _darkPrimaryGreen = Color(0xFF00E6AC);
  static const Color _darkLightGreen = Color(0xFF0F3D33);
  static const Color _darkDarkText = Color(0xFFF2F2F2);
  static const Color _darkGreyText = Color(0xFF9CA3AF);
  static const Color _darkWhite = Color(0xFF1E1E1E);
  static const Color _darkLightGrey = Color(0xFF2A2A2A);
  static const Color _darkBorderGrey = Color(0xFF3A3A3A);
  static const Color _darkSuccess = Color(0xFF34D399);
  static const Color _darkError = Color(0xFFF87171);
  static const Color _darkWarning = Color(0xFFFBBF24);
  static const Color _darkInfo = Color(0xFF60A5FA);
  static const Color _darkSurface = Color(0xFF121212);
  static const Color _darkSurfaceContainerHighest = Color(0xFF2C2C2C);
  static const Color _darkPrimaryContainer = Color(0xFF145C4C);
  static const Color _darkTertiaryContainer = Color(0xFF3A2E3D);
  static const Color _darkOutline = Color(0xFF8A8D8A);
  static const Color _darkOutlineVariant = Color(0xFF4A4D4A);
  static const Color _darkSurfaceContainer = Color(0xFF1C1C1C);
  static const Color _darkSurfaceContainerHigh = Color(0xFF242424);
  static const Color _darkErrorContainer = Color(0xFF4A2626);
  static const Color _darkOnSurfaceVariant = Color(0xFFC4C7C5);

  static const AppColors darkColors = AppColors(
    primaryGreen: _darkPrimaryGreen,
    lightGreen: _darkLightGreen,
    darkText: _darkDarkText,
    greyText: _darkGreyText,
    white: _darkWhite,
    lightGrey: _darkLightGrey,
    borderGrey: _darkBorderGrey,
    success: _darkSuccess,
    error: _darkError,
    warning: _darkWarning,
    info: _darkInfo,
    surface: _darkSurface,
    surfaceContainerHighest: _darkSurfaceContainerHighest,
    primaryContainer: _darkPrimaryContainer,
    tertiaryContainer: _darkTertiaryContainer,
    outline: _darkOutline,
    outlineVariant: _darkOutlineVariant,
    surfaceContainer: _darkSurfaceContainer,
    surfaceContainerHigh: _darkSurfaceContainerHigh,
    errorContainer: _darkErrorContainer,
    // "Fixed" se mantienen iguales que en el tema claro.
    primaryFixed: primaryFixed,
    secondaryFixed: secondaryFixed,
    tertiaryFixed: tertiaryFixed,
    onSurfaceVariant: _darkOnSurfaceVariant,
  );

  // ========== TEMA CLARO ==========
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: white,
    extensions: const [lightColors],

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: lightGreen,
      surface: surface,
      error: error,
      // Material 3 extended colors
      surfaceContainerHighest: surfaceContainerHighest,
      primaryContainer: primaryContainer,
      outline: outline,
      outlineVariant: outlineVariant,
      errorContainer: errorContainer,
      onSurfaceVariant: onSurfaceVariant,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: white,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: darkText,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: darkText,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: greyText,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: greyText,
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: greyText,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: greyText,
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Card (SIN shadowColor para evitar errores)
    cardTheme: const CardThemeData(
      color: white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryGreen,
      unselectedItemColor: greyText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // ========== TEMA OSCURO ==========
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimaryGreen,
    scaffoldBackgroundColor: _darkSurface,
    extensions: const [darkColors],

    colorScheme: const ColorScheme.dark(
      primary: _darkPrimaryGreen,
      secondary: _darkLightGreen,
      surface: _darkSurface,
      error: _darkError,
      surfaceContainerHighest: _darkSurfaceContainerHighest,
      primaryContainer: _darkPrimaryContainer,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      errorContainer: _darkErrorContainer,
      onSurfaceVariant: _darkOnSurfaceVariant,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: _darkWhite,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: _darkDarkText),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkDarkText,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkDarkText,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkDarkText,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _darkDarkText,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkDarkText,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _darkDarkText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: _darkDarkText,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: _darkDarkText,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: _darkGreyText,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _darkDarkText,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _darkGreyText,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkLightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkError, width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _darkGreyText,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _darkGreyText,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryGreen,
        foregroundColor: _darkSurface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: const CardThemeData(
      color: _darkWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkWhite,
      selectedItemColor: _darkPrimaryGreen,
      unselectedItemColor: _darkGreyText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // ========== SOMBRAS PERSONALIZADAS ==========
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // ========== BORDER RADIUS ==========
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius mediumRadius =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(24));
}

// ========== TAMAÑOS Y ESPACIADOS ==========
class AppSizes {
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;

  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
}
