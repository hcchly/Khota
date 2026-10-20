import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khota_app/models/report_draft.dart';
import 'package:khota_app/screens/reports/report_photo_screen.dart';
import 'package:khota_app/screens/settings/settings_screen.dart';
import 'package:khota_app/settings/app_settings.dart';
import 'package:khota_app/theme/app_theme.dart';

import 'helpers/report_fakes.dart';

import 'package:khota_app/screens/reports/new_report_screen.dart';

Widget host(Widget child, double scale) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
  });
  test(
    'accessibility settings persist and invalid saved scale uses default',
    () async {
      await AppSettings.instance.setTextScaleIndex(3);
      await AppSettings.instance.setBoldText(true);
      await AppSettings.instance.load();
      expect(AppSettings.instance.textScale, 1.3);
      expect(AppSettings.instance.boldText, isTrue);
      SharedPreferences.setMockInitialValues({'text_scale': -2.0});
      await AppSettings.instance.load();
      expect(AppSettings.instance.textScale, 1.0);
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets('current report flow fits RTL at scale $scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        host(
          NewReportScreen(
            initialDraft: ReportDraft(imageBytes: testPhoto),
            camera: FakeCamera(),
            locationProvider: FakeLocationProvider(),
          ),
          scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('استخدام الصورة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('تأكيد الموقع').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(TextField),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.labelText,
        'تفاصيل إضافية (اختياري)',
      );
    });
    testWidgets('settings fits 320px RTL at scale $scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(host(const SettingsScreen(), scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('report fits and has labeled description at scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        host(
          ReportPhotoScreen(
            initialDraft: ReportDraft(imageBytes: testPhoto),
            camera: FakeCamera(),
          ),
          scale,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.labelText, 'تفاصيل إضافية (اختياري)');
      await tester.enterText(find.byType(TextField), 'رصيف مكسور');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('تفاصيل إضافية')), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('حفظ الصورة والتفاصيل'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }
}
