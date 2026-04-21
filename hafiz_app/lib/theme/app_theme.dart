import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0A0E21);
  static const surface = Color(0xFF1D1E33);
  static const surfaceVariant = Color(0xFF252642);
  static const primary = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF388E3C);
  static const gold = Color(0xFFFFD700);
  static const text = Color(0xFFECECEC);
  static const textSecondary = Color(0xFF9E9EBD);
  static const error = Color(0xFFEF5350);
  static const success = Color(0xFF66BB6A);
  static const warning = Color(0xFFFFCA28);
  static const cardGradient1 = Color(0xFF1A3A4A);
  static const cardGradient2 = Color(0xFF0D2535);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        onSurface: AppColors.text,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineMedium: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w500, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
