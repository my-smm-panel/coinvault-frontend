import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFFF7A00);
  static const orangeLight = Color(0xFFFF9800);
  static const orangeDeep = Color(0xFFFF6A00);
  static const orangeSoft = Color(0xFFFFE9D6);
  static const gold = Color(0xFFFFC83A);
  static const white = Colors.white;
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const bg = Color(0xFFF3F5F8);
  static const line = Color(0xFFE5E7EB);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFE8F8EE);
  static const purple = Color(0xFF7C3AED);
  static const blue = Color(0xFF2563EB);
  static const red = Color(0xFFDC2626);
  static const dark = Color(0xFF141821);
  static const darkSoft = Color(0xFF1D2430);

  static const brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orangeLight, orange],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF12161F), Color(0xFF1F2634)],
  );
}
