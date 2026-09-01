import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette - clean, modern
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFFEEF0FF);
  
  // Accent - Gold for coins
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldContainer = Color(0xFFFFF4E5);
  
  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Border/divider
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Text styles
class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2,
  );
  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2,
  );
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3,
  );
  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3,
  );
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
  );
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
  );
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5,
  );
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5,
  );
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary, height: 1.5,
  );
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary, height: 1.4,
  );
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.4,
  );
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

/// Shadows
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}