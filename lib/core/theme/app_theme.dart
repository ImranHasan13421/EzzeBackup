import 'package:flutter/material.dart';

class AppColors {
  // Brand Gradient — used for hero elements, CTAs, and accent areas
  static const Color brandStart = Color(0xFF4F46E5);  // Indigo-600
  static const Color brandEnd = Color(0xFF7C3AED);     // Violet-600
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandStart, brandEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary Accent
  static const Color primaryBlue = Color(0xFF4F46E5);    // Indigo-600
  static const Color primaryBlueHover = Color(0xFF4338CA); // Indigo-700
  static const Color primaryBlueSubtle = Color(0xFFEEF2FF); // Indigo-50

  // Secondary Accent (Teal for contrast actions)
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentTealSubtle = Color(0xFFF0FDFA);

  // Status Indicators
  static const Color successGreen = Color(0xFF22C55E);
  static const Color successGreenSubtle = Color(0xFFF0FDF4);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberSubtle = Color(0xFFFFFBEB);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedSubtle = Color(0xFFFEF2F2);

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Mode Palette — Deep space aesthetic
  static const Color darkBackground = Color(0xFF0C0A1D);
  static const Color darkSurface = Color(0xFF141229);
  static const Color darkSurfaceVariant = Color(0xFF1E1B3A);
  static const Color darkSurfaceElevated = Color(0xFF252347);
  static const Color darkTextPrimary = Color(0xFFF1F0FF);
  static const Color darkTextSecondary = Color(0xFF9B97C0);
  static const Color darkTextTertiary = Color(0xFF6B6898);
  static const Color darkBorder = Color(0xFF2D2A52);

  // Glass / Frosted Surface Colors
  static const Color glassLight = Color(0x40FFFFFF);
  static const Color glassDark = Color(0x20FFFFFF);
}
