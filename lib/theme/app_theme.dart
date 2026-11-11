import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'khota_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(KhotaColors.light);

  static ThemeData dark() => _build(KhotaColors.dark);

  static ThemeData _build(KhotaColors c) {
    const fontFamily = 'KhotaArabic';
    final dark = c.isDark;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    var scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.ocean,
          brightness: c.brightness,
        ).copyWith(
          primary: c.primary,
          onPrimary: c.onPrimary,
          secondary: AppColors.mint,
          onSecondary: dark ? c.onPrimary : Colors.white,
          surface: c.surface,
          onSurface: c.text,
          error: AppColors.error,
          outline: c.outline,
        );
    if (dark) {
      // Sheets, dialogs and menus use the brand card colour, not seed tones.
      scheme = scheme.copyWith(
        onSurfaceVariant: c.mutedText,
        outlineVariant: c.divider,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surface,
        surfaceContainerHighest: c.surface,
        surfaceTint: Colors.transparent,
      );
    }

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
    );

    var theme = base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: c.text,
        displayColor: c.text,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(c.outline),
        enabledBorder: border(
          dark ? c.outline : AppColors.ocean.withValues(alpha: 0.12),
        ),
        disabledBorder: border(c.divider),
        focusedBorder: border(c.primary, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: dark ? c.divider : AppColors.slate,
          disabledForegroundColor: dark ? c.mutedText : null,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
          foregroundColor: c.primary,
          side: BorderSide(color: c.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: dark
            ? WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? c.onPrimary
                    : c.mutedText,
              )
            : WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : (dark ? c.background : AppColors.slate),
        ),
        trackOutlineColor: dark
            ? WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.transparent
                    : c.mutedText,
              )
            : WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.primary.withValues(alpha: dark ? 0.18 : 0.12),
        thumbColor: c.primary,
        overlayColor: AppColors.mint.withValues(alpha: 0.15),
        activeTickMarkColor: dark ? c.onPrimary : Colors.white,
        inactiveTickMarkColor: c.text.withValues(alpha: 0.3),
        valueIndicatorColor: dark ? c.primary : null,
        valueIndicatorTextStyle: dark ? TextStyle(color: c.onPrimary) : null,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.snackBar,
        contentTextStyle: TextStyle(color: c.onSnackBar),
        actionTextColor: dark ? c.primary : null,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: dark ? c.background : AppColors.gradientTop,
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

    if (dark) {
      theme = theme.copyWith(
        cardTheme: CardThemeData(
          color: c.surface,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: c.surface,
          modalBackgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          dragHandleColor: c.mutedText,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: DividerThemeData(color: c.divider),
        listTileTheme: ListTileThemeData(
          textColor: c.text,
          iconColor: c.mutedText,
          // Subtitles use colorScheme.onSurfaceVariant (muted text). A
          // subtitleTextStyle here would break the light/dark transition.
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: c.primary,
          linearTrackColor: c.divider,
        ),
      );
    }
    return theme;
  }
}
