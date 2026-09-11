import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primaryLight = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF8AB4F8);
  static const Color secondary = Color(0xFF5F6368);

  // Light theme
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F3F4);
  static const Color textPrimaryLight = Color(0xFF202124);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textDisabledLight = Color(0xFF9AA0A6);
  static const Color dividerLight = Color(0xFFE8EAED);

  // Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);
  static const Color textDisabledDark = Color(0xFF5F6368);
  static const Color dividerDark = Color(0xFF3C4043);

  // Semantic
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF4285F4);

  // Call-specific
  static const Color callAccept = Color(0xFF34A853);
  static const Color callReject = Color(0xFFEA4335);
  static const Color callEnd = Color(0xFFEA4335);
  static const Color online = Color(0xFF34A853);
  static const Color offline = Color(0xFF9AA0A6);
  static const Color busy = Color(0xFFFBBC04);

  // Call screen
  static const Color callBackground = Color(0xFF1A1A2E);
  static const Color callSurface = Color(0xFF16213E);
  static const Color callControlBackground = Color(0xFF2C2C44);
  static const Color callControlActive = Color(0xFFFFFFFF);

  // Missed/Incoming/Outgoing
  static const Color missedCall = Color(0xFFEA4335);
  static const Color incomingCall = Color(0xFF34A853);
  static const Color outgoingCall = Color(0xFF1A73E8);
}
