import 'package:flutter/material.dart';

class AppColors {
  // Primary accent
  static const blue400 = Color(0xFF378ADD);
  static const blue600 = Color(0xFF185FA5);

  // Completion states
  static const green400 = Color(0xFF639922);
  static const green50 = Color(0xFFEAF3DE);
  static const green800 = Color(0xFF27500A);

  // Warning
  static const amber400 = Color(0xFFBA7517);
  static const amber50 = Color(0xFFFAEEDA);

  // Danger / missed
  static const red400 = Color(0xFFE24B4A);
  static const red600 = Color(0xFFA32D2D);
  static const red50 = Color(0xFFFCEBEB);

  // Neutral
  static const gray200 = Color(0xFFD3D1C7);
  static const gray300 = Color(0xFFB0AEA7);
  static const gray500 = Color(0xFF7A7870);
  static const gray700 = Color(0xFF4F4D5A);
  static const gray900 = Color(0xFF1F1D2B);

  // Light surface
  static const lightBackground = Color(0xFFF6F5F1);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFEEEDE8);

  // Dark surface
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);

  // Score color helpers
  static Color scoreColor(double rate) {
    if (rate >= 0.8) return green400;
    if (rate >= 0.5) return amber400;
    return red400;
  }

  static Color scoreBg(double rate) {
    if (rate >= 0.8) return green50;
    if (rate >= 0.5) return amber50;
    return red50;
  }
}
