import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Khota colours for the current brightness, read with `context.khota`.
///
/// Light values are the existing [AppColors]; dark values come only from the
/// brand book (page #011E26, cards #0A2C37, navigation #062530, text #E8EBEE,
/// accent #40BA87).
@immutable
class KhotaColors extends ThemeExtension<KhotaColors> {
  const KhotaColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.navBar,
    required this.text,
    required this.mutedText,
    required this.primary,
    required this.onPrimary,
    required this.cardBorder,
    required this.outline,
    required this.divider,
    required this.shadow,
    required this.snackBar,
    required this.onSnackBar,
    required this.headerFallback,
    required this.headerImage,
    required this.splashImage,
  });

  final Brightness brightness;

  /// Page background.
  final Color background;

  /// Cards, sheets, fields.
  final Color surface;

  /// Panels set inside a card (status boxes, previews, thumbnails).
  final Color surfaceSunken;

  /// Bottom navigation bar and the ring around the centre button.
  final Color navBar;

  /// Body text and dark details.
  final Color text;

  /// Secondary text in dark mode (#E8EBEE at 66%). In light mode secondary
  /// text keeps its existing per-place opacity, see [muted].
  final Color mutedText;

  /// Primary buttons, selected items, links and accent icons.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Thin card outline.
  final Color cardBorder;

  /// Chip and field outlines, disabled states, placeholder icons.
  final Color outline;

  /// Light dividers and badge backgrounds.
  final Color divider;

  final Color shadow;
  final Color snackBar;
  final Color onSnackBar;

  /// Shown behind the pattern image until it is decoded.
  final Gradient headerFallback;

  /// Pattern art for headers, app bars and intro cards.
  final String headerImage;

  /// Full-screen pattern art for the splash.
  final String splashImage;

  bool get isDark => brightness == Brightness.dark;

  /// Error stays the brand red in both modes.
  Color get error => AppColors.error;

  /// Mint is the same in both modes.
  Color get mint => AppColors.mint;

  /// Solid badge on a header pattern (current step, avatar, success tick):
  /// white in light mode, the selected green in dark mode.
  Color get headerBadge => isDark ? primary : Colors.white;

  /// Text and icons on [headerBadge].
  Color get onHeaderBadge => isDark ? onPrimary : AppColors.greenDeep;

  /// Secondary text. Light mode keeps the opacity each place already used;
  /// dark mode always uses the brand's 66% text.
  Color muted([double lightAlpha = 0.6]) =>
      isDark ? mutedText : text.withValues(alpha: lightAlpha);

  /// Soft tinted tile/badge fill behind an accent icon.
  Color tint(Color color, double alpha) => isDark
      ? color.withValues(alpha: 0.18)
      : Color.alphaBlend(color.withValues(alpha: alpha), Colors.white);

  /// Status chips: dark mode uses amber for pending and green for the rest.
  (Color, Color) chip({bool pending = false}) {
    final c = pending ? AppColors.amber : AppColors.mint;
    return (c.withValues(alpha: 0.18), c);
  }

  /// Light mode: today's colours.
  static const light = KhotaColors(
    brightness: Brightness.light,
    background: AppColors.sand,
    surface: AppColors.warmWhite,
    surfaceSunken: AppColors.sand,
    navBar: AppColors.mist,
    text: AppColors.ink,
    mutedText: Color(0x991D2421), // ink at 60%
    primary: AppColors.greenDeep,
    onPrimary: Colors.white,
    cardBorder: Color(0x12237A57), // greenDeep at 7%
    outline: AppColors.slate,
    divider: AppColors.mist,
    shadow: Color(0x091D2421), // ink at 3.5%
    snackBar: AppColors.charcoal,
    onSnackBar: Colors.white,
    headerFallback: AppColors.brandGradient,
    headerImage: 'assets/images/brand_light_header.jpg',
    splashImage: 'assets/images/brand_light_splash.jpg',
  );

  /// Dark mode: brand book colours only.
  static const dark = KhotaColors(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceSunken: AppColors.darkBackground,
    navBar: AppColors.darkNavBar,
    text: AppColors.darkText,
    mutedText: Color(0xA8E8EBEE), // #E8EBEE at 66%
    primary: AppColors.mint,
    onPrimary: AppColors.darkBackground,
    cardBorder: Color(0x17E8EBEE), // #E8EBEE at 9%
    outline: Color(0x17E8EBEE),
    divider: Color(0x17E8EBEE),
    shadow: Color(0x00000000),
    snackBar: AppColors.darkSurface,
    onSnackBar: AppColors.darkText,
    headerFallback: LinearGradient(
      colors: [AppColors.darkBackground, AppColors.darkBackground],
    ),
    headerImage: 'assets/images/brand_dark_header.jpg',
    splashImage: 'assets/images/brand_dark_splash.jpg',
  );

  @override
  KhotaColors copyWith() => this;

  /// Theme switches swap the whole palette; the pattern art cannot blend.
  @override
  KhotaColors lerp(KhotaColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension KhotaColorsContext on BuildContext {
  /// The Khota palette for the current theme (light if none is set).
  KhotaColors get khota =>
      Theme.of(this).extension<KhotaColors>() ?? KhotaColors.light;
}
