import 'package:flutter/material.dart';

/// Semantic palette for CampusFix mobile application.
/// Primary: Deep Navy Blue
/// Secondary / Accent: Fresh Campus Green
class AppColors {
  AppColors._();

  // Primary Navy Spectrum
  static const Color primaryNavy = Color(0xFF142238);
  static const Color primaryNavyLight = Color(0xFF1E3250);
  static const Color primaryNavyDark = Color(0xFF0C1625);
  static const Color primaryNavyMuted = Color(0xFFE8EEF5);

  // Secondary Fresh Green Spectrum
  static const Color accentGreen = Color(0xFF16865C);
  static const Color accentGreenLight = Color(0xFF28A779);
  static const Color accentGreenDark = Color(0xFF0F5E40);
  static const Color accentGreenMuted = Color(0xFFE8F5F0);

  // Neutral Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF1E3250);

  // Status & Priority Tints
  static const Color statusSubmitted = Color(0xFF3B82F6);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF10B981);
  static const Color statusClosed = Color(0xFF64748B);
  static const Color statusRejected = Color(0xFFEF4444);

  // Priority Tints
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFF3B82F6);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityUrgent = Color(0xFFDC2626);
}
