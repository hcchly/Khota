
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final String? fontFamily =
        GoogleFonts.ibmPlexSansArabic().fontFamily;

    OutlineInputBorder border(
      Color color, [
      double width = 1,
    ]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: color,
            width: width,
          ),
        );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ocean,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.ocean,
        onPrimary: Colors.white,
        secondary: AppColors.mint,
        onSecondary: AppColors.ink,
        surface: AppColors.warmWhite,
        onSurface: AppColors.ink,
        error: AppColors.error,
        outline: AppColors.slate,
      ),
      scaffoldBackgroundColor: AppColors.sand,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.warmWhite,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(AppColors.slate),
        enabledBorder: border(AppColors.slate),
        disabledBorder: border(AppColors.slate),
        focusedBorder: border(AppColors.ocean, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ocean,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slate,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ocean,
          side: const BorderSide(
            color: AppColors.slate,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ocean,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(
          Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(
            WidgetState.selected,
          )
              ? AppColors.ocean
              : AppColors.slate,
        ),
        trackOutlineColor:
            WidgetStateProperty.all(
          Colors.transparent,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.ocean,
        inactiveTrackColor:
            AppColors.slate.withValues(alpha: 0.5),
        thumbColor: AppColors.ocean,
        overlayColor:
            AppColors.mint.withValues(alpha: 0.15),
        activeTickMarkColor: Colors.white,
        inactiveTickMarkColor:
            AppColors.ink.withValues(alpha: 0.3),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          color: Colors.white,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ocean,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
