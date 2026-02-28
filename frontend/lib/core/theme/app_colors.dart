import 'package:flutter/material.dart';

/// Centralized color palette for light/dark themes.
class AppColors {
  AppColors._();

  // Primary (iOS-style blue)
  static const Color primaryLight = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0A84FF);

  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF121212);

  static const Color cardFrontLight = Color(0xFFFFFFFF);
  static const Color cardFrontDark = Color(0xFF1E1E1E);
  static const Color cardBackLight = Color(0xFFE8EAF6);
  static const Color cardBackDark = Color(0xFF2D2D3A);

  // Difficulty colors (SRS buttons)
  static const Color again = Color(0xFFE53935);
  static const Color hard = Color(0xFFFF9800);
  static const Color good = Color(0xFF43A047);
  static const Color easy = Color(0xFF1E88E5);

  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF2E7D32);
}
