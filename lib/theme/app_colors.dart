import 'package:flutter/material.dart';

/// Khota brand colors - Light Mode.
///
/// The brand palette is green (#40BA87) and light grey (#E8EBEE). The app is
/// light: white / light-grey surfaces, green accents, and the brand gradient
/// (#115A73 → #40BA87, brand book p. 11) only on the splash and page headers.
/// Navy is no longer used anywhere in the interface.
class AppColors {
  AppColors._();

  // Brand palette
  static const Color mint = Color(0xFF40BA87); // accent green
  static const Color mist = Color(0xFFE8EBEE); // brand light grey

  /// The accent green darkened for text, icons and buttons on white, so they
  /// stay readable (WCAG contrast); mint itself is too light for small text.
  static const Color greenDeep = Color(0xFF237A57);

  /// Neutral charcoal for text (not navy).
  static const Color charcoal = Color(0xFF1D2421);

  /// Brand gradient (brand book p. 11): top and bottom stops.
  static const Color gradientTop = Color(0xFF115A73);
  static const Color gradientBottom = mint;
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );

  // Names used across the app, remapped to the light theme so every screen
  // follows it without navy.
  static const Color ink = charcoal; // text and dark details
  static const Color ocean = greenDeep; // primary actions and links
  static const Color indigo = ink;
  static const Color teal = ocean;
  static const Color tealLight = mint;

  // Light mode backgrounds
  static const Color sand = Color(0xFFF5F6F7); // page background
  static const Color warmWhite = Color(0xFFFFFFFF); // cards
  static const Color slate = Color(0xFFBCC3C0); // borders, disabled

  // Alerts
  static const Color error = Color(0xFFC0392B);
  static const Color amber = Color(0xFFB56A12);
}
