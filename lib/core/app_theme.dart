import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette - CoinVault light theme (per design sheet)
class AppColors {
  // Unified CoinVault orange/gold palette from the supplied UI reference.
  static const Color primary = Color(0xFFF59E0B);
  static const Color primaryLight = Color(0xFFFBBF24);
  static const Color primaryDark = Color(0xFFD97706);
  static const Color primaryContainer = Color(0xFFFFF4E5);

  // Accent - the same warm gold used for coin rewards.
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldContainer = Color(0xFFFFF7E6);

  // Soft neutral surfaces keep the reward cards clear and readable.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F6F8);
  static const Color background = Color(0xFFFAFAF8);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors (light theme)
  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9B9BAB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Dark surfaces (unused in light, kept for compat)
  static const Color spinDark = Color(0xFFFFF7E6);
  static const Color spinCard = Color(0xFFFFFFFF);

  // Border/divider (light theme)
  static const Color divider = Color(0xFFE8E8EE);
  static const Color border = Color(0xFFE2E2EA);

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
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFCF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warm CoinVault brand gradient used across headers and reward highlights.
  static const LinearGradient brandHeader = LinearGradient(
    colors: [primary, primaryDark],
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
  static const double xxl = 32;
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