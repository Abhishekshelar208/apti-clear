import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color _primaryLight = Color(0xFF2563EB); // Royal Blue
  static const Color _primaryDark = Color(0xFF3B82F6); // Sky Blue
  static const Color _secondaryLight = Color(0xFF059669); // Emerald Green
  static const Color _secondaryDark = Color(0xFF10B981); // Emerald Green (Dark)
  
  static const Color _backgroundLight = Color(0xFFF8F9FA); // Off-white
  static const Color _backgroundDark = Color(0xFF0F172A); // Deep Slate
  
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1E293B); // Lighter Slate/Gray for cards
  
  static const Color _errorColor = Color(0xFFDC2626); // Red-600

  // Text Theme
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -1.0
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.bold, color: textColor
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700, color: textColor
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: textColor
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: textColor
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w500, color: textColor
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: textColor
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: textColor
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        secondary: _secondaryLight,
        surface: _surfaceLight,
        error: _errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        brightness: Brightness.light,
      ),
      textTheme: _buildTextTheme(base.textTheme, Colors.black87),
      cardTheme: CardThemeData(
        color: _surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: _primaryLight, width: 1.5),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.black87,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, 
          fontWeight: FontWeight.w700, 
          color: Colors.black87
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: _primaryDark,
      scaffoldBackgroundColor: _backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        secondary: _secondaryDark,
        surface: _surfaceDark,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(base.textTheme, Colors.white),
      cardTheme: CardThemeData(
        color: _surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: _primaryDark, width: 1.5),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _surfaceDark,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, 
          fontWeight: FontWeight.w700, 
          color: Colors.white
        ),
      ),
    );
  }
}
