import 'package:flutter/material.dart';

/// Khota new brand palette.
class AppColors {
  AppColors._();

  // Brand colors from guidelines
  static const Color ink = Color(0xFF011E26);   // darkest
  static const Color ocean = Color(0xFF115A73); // primary
  static const Color mint = Color(0xFF40BA87);  // accent
  static const Color mist = Color(0xFFE8EBEE);  // light neutral

  // Keep old names so the rest of the app does not break
  static const Color indigo = ocean;
  static const Color teal = mint;
  static const Color tealLight = Color(0xFF8CDABB);

  // Global surfaces
  static const Color sand = ink;        // app background (dark)
  static const Color warmWhite = mist;  // cards and input fields
  static const Color slate = Color(0xFF89A5AF); // borders / disabled

  static const Color error = Color(0xFFD95D5D);
  static const Color amber = Color(0xFFF2C14E);
}
