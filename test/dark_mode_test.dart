import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khota_app/models/app_user.dart';
import 'package:khota_app/models/report_location.dart';
import 'package:khota_app/models/submitted_report.dart';
import 'package:khota_app/screens/home/home_screen.dart';
import 'package:khota_app/screens/reports/report_submitted_screen.dart';
import 'package:khota_app/screens/settings/settings_screen.dart';
import 'package:khota_app/services/profile_service.dart';
import 'package:khota_app/settings/app_settings.dart';
import 'package:khota_app/theme/app_colors.dart';
import 'package:khota_app/theme/app_theme.dart';
import 'package:khota_app/theme/khota_colors.dart';
import 'package:khota_app/widgets/brand_surface.dart';
import 'package:khota_app/widgets/gradient_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfile implements ProfileService {
  static const user = AppUser(
    uid: 'u1',
    fullName: 'ريم الشلوي',
    email: 'reem@example.com',
  );

  @override
  Future<AppUser> getProfile() async => user;

  @override
  Future<AppUser> updateName(String fullName) async =>
      user.copyWith(fullName: fullName);
}

/// Same wiring as KhotaApp: follows AppSettings.themeMode live.
Widget host(Widget child, {double scale = 1.0}) => ListenableBuilder(
  listenable: AppSettings.instance,
  builder: (context, _) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: AppSettings.instance.themeMode,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);

Future<void> scrollToEnd(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
  });

  group('appearance setting', () {
    test('defaults to following the device', () {
      expect(AppSettings.instance.themeMode, ThemeMode.system);
    });

    test('persists the chosen mode across loads', () async {
      await AppSettings.instance.setThemeMode(ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      await AppSettings.instance.load();
      expect(AppSettings.instance.themeMode, ThemeMode.dark);

      await AppSettings.instance.setThemeMode(ThemeMode.light);
      await AppSettings.instance.load();
      expect(AppSettings.instance.themeMode, ThemeMode.light);
    });

    test('an unknown saved value falls back to the device', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
      await AppSettings.instance.load();
      expect(AppSettings.instance.themeMode, ThemeMode.system);
    });
  });

  group('dark theme', () {
    test('uses the brand book palette', () {
      final theme = AppTheme.dark();
      final colors = theme.extension<KhotaColors>()!;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF011E26));
      expect(colors.surface, const Color(0xFF0A2C37));
      expect(colors.navBar, const Color(0xFF062530));
      expect(colors.text, const Color(0xFFE8EBEE));
      expect(colors.primary, const Color(0xFF40BA87));
      expect(colors.onPrimary, const Color(0xFF011E26));
      expect(colors.headerImage, 'assets/images/brand_dark_header.jpg');
    });

    test('light theme keeps the current colours', () {
      final theme = AppTheme.light();
      expect(theme.scaffoldBackgroundColor, AppColors.sand);
      expect(theme.colorScheme.primary, AppColors.ocean);
      expect(
        theme.extension<KhotaColors>()!.headerImage,
        'assets/images/brand_light_header.jpg',
      );
    });
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('HomeScreen builds in dark mode at 320x640, scale $scale', (
      tester,
    ) async {
      await AppSettings.instance.setThemeMode(ThemeMode.dark);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        host(
          Scaffold(
            body: HomeScreen(onOpenTab: (_) {}, service: _FakeProfile()),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(find.text(_FakeProfile.user.fullName), findsOneWidget);

      // The header shows the dark brand pattern.
      final surface = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BrandSurface),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final image =
          (surface.decoration as BoxDecoration).image!.image as AssetImage;
      expect(image.assetName, 'assets/images/brand_dark_header.jpg');

      await scrollToEnd(tester);
    });

    testWidgets('SettingsScreen builds in dark mode at 320x640, scale $scale', (
      tester,
    ) async {
      await AppSettings.instance.setThemeMode(ThemeMode.dark);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(host(const SettingsScreen(), scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      await scrollToEnd(tester);
    });
  }

  testWidgets('choosing an appearance applies it immediately', (tester) async {
    await AppSettings.instance.setThemeMode(ThemeMode.light);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(const SettingsScreen()));
    await tester.pumpAndSettle();

    Brightness brightness() =>
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness;
    expect(brightness(), Brightness.light);
    expect(find.text('المظهر'), findsOneWidget);

    final dark = find.byKey(const ValueKey('theme-dark'));
    await tester.ensureVisible(dark);
    await tester.pumpAndSettle();
    await tester.tap(dark);
    await tester.pumpAndSettle();
    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(brightness(), Brightness.dark);

    final system = find.byKey(const ValueKey('theme-system'));
    await tester.ensureVisible(system);
    await tester.pumpAndSettle();
    await tester.tap(system);
    await tester.pumpAndSettle();
    expect(AppSettings.instance.themeMode, ThemeMode.system);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'system');
  });

  group('status bar', () {
    Brightness? iconsOf(WidgetTester tester, Finder region) => tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(region)
        .value
        .statusBarIconBrightness;

    for (final (mode, icons) in [
      (ThemeMode.light, Brightness.dark),
      (ThemeMode.dark, Brightness.light),
    ]) {
      testWidgets('plain page uses ${icons.name} icons in ${mode.name} mode', (
        tester,
      ) async {
        await AppSettings.instance.setThemeMode(mode);
        await tester.pumpWidget(
          host(
            const ReportSubmittedScreen(
              report: SubmittedReport(
                id: 'abCD12efGH34ijKL56mn',
                location: ReportLocation(
                  latitude: 24.7,
                  longitude: 46.6,
                  source: ReportLocation.sourceGps,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final region = find
            .descendant(
              of: find.byType(ReportSubmittedScreen),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first;
        expect(iconsOf(tester, region), icons);
      });

      testWidgets('patterned header keeps light icons in ${mode.name} mode', (
        tester,
      ) async {
        await AppSettings.instance.setThemeMode(mode);
        await tester.pumpWidget(
          host(
            Scaffold(
              body: HomeScreen(onOpenTab: (_) {}, service: _FakeProfile()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final header = find
            .descendant(
              of: find.byType(GradientHeader),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first;
        expect(iconsOf(tester, header), Brightness.light);
      });
    }
  });
}
