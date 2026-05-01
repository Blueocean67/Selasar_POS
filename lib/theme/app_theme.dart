import 'package:flutter/material.dart';
import 'app_colors.dart'; 

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryOlive,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'PlusJakartaSans', 

      // Skema Warna Global
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOlive,
        primary: AppColors.primaryOlive,
        secondary: AppColors.accentGold,
        tertiary: AppColors.primaryDark, // Untuk elemen branding gelap
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),

      // Gaya AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Gaya Card
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),

      // Gaya Input Form
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3EE), // Sedikit lebih terang
        hintStyle: const TextStyle(color: AppColors.inputHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryOlive, width: 1.5),
        ),
      ),

      // Gaya Tombol Utama (Warna Olive sesuai Gambar Desain)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOlive,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      // Gaya Teks Global
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary, 
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary, 
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}