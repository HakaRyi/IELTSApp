import 'package:flutter/material.dart';

/// Bảng màu chủ đạo: trắng + xanh dương, kèm các màu phụ trợ.
class AppColors {
  static const Color primary = Color(0xFF2563EB); // xanh dương chính
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accent = Color(0xFF06B6D4); // cyan phụ trợ
  static const Color surface = Color(0xFFFFFFFF); // trắng
  static const Color background = Color(0xFFF5F8FF); // trắng ngả xanh rất nhẹ
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Màu cho sắc thái nghĩa (connotation)
  static const Color positive = Color(0xFF16A34A);
  static const Color negative = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF2563EB);
  static const Color formal = Color(0xFF7C3AED);
  static const Color informal = Color(0xFFEA580C);

  static Color forConnotation(String c) {
    switch (c.toLowerCase()) {
      case 'positive':
        return positive;
      case 'negative':
        return negative;
      case 'formal':
        return formal;
      case 'informal':
        return informal;
      default:
        return neutral;
    }
  }
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
