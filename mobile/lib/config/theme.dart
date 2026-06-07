// ============================================
// TEMA Y COLORES DE UNIPLAN
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ========== COLORES MATERIAL DESIGN 3 ==========
  static const Color primaryGreen = Color(0xFF00D9A0);
  static const Color lightGreen = Color(0xFFE0F9F4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color borderGrey = Color(0xFFE5E7EB);

  // Colores adicionales
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Material Design 3 - Surface colors
  static const Color surface = Color(0xFFFAFBFC);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E1);
  static const Color primaryContainer = Color(0xFFA8F0DD);
  static const Color tertiaryContainer = Color(0xFFF5E6F7);
  static const Color outline = Color(0xFF747775);
  static const Color outlineVariant = Color(0xFFC4C7C5);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFEAEAEA);
  static const Color errorContainer = Color(0xFFF9DEDC);

  // Fixed colors (M3)
  static const Color primaryFixed = Color(0xFFB8F0DD);
  static const Color secondaryFixed = Color(0xFFD6E5F5);
  static const Color tertiaryFixed = Color(0xFFF5E6F7);
  static const Color onSurfaceVariant = Color(0xFF404944);

  // ========== TEMA CLARO ==========
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: white,

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
