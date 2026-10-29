import 'package:flutter/material.dart';

/// Khota brand colors - Light Mode
class AppColors {
  AppColors._();

  // Original brand colors
  static const Color ink = Color(0xFF011E26);
  static const Color ocean = Color(0xFF115A73);
  static const Color mint = Color(0xFF40BA87);
  static const Color mist = Color(0xFFE8EBEE);

  // Keep existing names to avoid breaking old screens
  static const Color indigo = ink;
  static const Color teal = ocean;
  static const Color tealLight = mint;

  // Light mode backgrounds
  static const Color sand = Color(0xFFF5F8F9);
  static const Color warmWhite = Color(0xFFFFFFFF);
  static const Color slate = Color(0xFFB5C8CE);

  // Alerts
  static const Color error = Color(0xFFC0392B);
  static const Color amber = Color(0xFFB56A12);
}
