import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khota_app/screens/reports/report_details_screen.dart';
import 'package:khota_app/screens/reports/reports_screen.dart';
import 'package:khota_app/theme/app_colors.dart';
import 'package:khota_app/theme/app_theme.dart';
import 'package:khota_app/utils/report_labels.dart';
import 'package:khota_app/utils/report_sort.dart';
import 'package:khota_app/widgets/report_map_marker.dart';
import 'package:khota_app/widgets/report_status_widgets.dart';

Widget host(
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  double scale = 1.0,
}) => MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: mode,
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

// Firestore IDs are 20 characters; the list shows "KHT-" + the first 8.
final older = CitizenReport(
  id: 'aaaaaaaa000000000001',
  description: 'بلاغ قديم',
  reportStatus: ReportStatusLabels.resolved,
  analysisStatus: 'اكتمل تحليل الصورة',
  createdAt: DateTime(2026, 10, 1),
  address: 'حي الملقا',
  issueClass: 'surface_damage',
  severity: 'severe',
);
final newest = CitizenReport(
  id: 'bbbbbbbb000000000002',
  description: 'بلاغ أحدث',
  reportStatus: ReportStatusLabels.pending,
  analysisStatus: ReportStatusLabels.analyzing,
  createdAt: DateTime(2026, 11, 10),
  address: 'حي العليا، طريق الملك فهد',
);
final middle = CitizenReport(
  id: 'cccccccc000000000003',
  description: 'بلاغ متوسط',
  reportStatus: ReportStatusLabels.inProgress,
  analysisStatus: ReportStatusLabels.analyzing,
  createdAt: DateTime(2026, 10, 20),
  address: 'حي النرجس',
);

double topOf(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('newest-first sorting (shared with Home)', () {
    test('orders by date, newest first; undated last; ties by ID', () {
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 2, 1);
      expect(compareNewestFirst(b, 'x', a, 'y'), lessThan(0));
      expect(compareNewestFirst(a, 'x', b, 'y'), greaterThan(0));
      expect(compareNewestFirst(null, 'x', a, 'y'), greaterThan(0));
      expect(compareNewestFirst(a, 'x', null, 'y'), lessThan(0));
      expect(compareNewestFirst(a, 'a', a, 'b'), lessThan(0));
    });

    test('CitizenReport.newestFirst sorts a list', () {
      final list = [older, newest, middle]..sort(CitizenReport.newestFirst);
      expect(list.map((r) => r.id), [newest.id, middle.id, older.id]);
    });
  });

  test('fromMap reads date, place, and analysis results', () {
    final report = CitizenReport.fromMap('r1', {
      'description': '  رصيف مكسور ',
      'reportStatus': 'in_progress',
      'analysisStatus': 'processing',
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 10, 12)),
      'location': const GeoPoint(24.7, 46.6),
      'address': ' حي العليا ',
      'issueClass': 'curb_ramp_issue',
      'severity': null,
    });
    expect(report.description, 'رصيف مكسور');
    expect(report.reportStatus, ReportStatusLabels.inProgress);
    expect(report.analysisStatus, ReportStatusLabels.analyzing);
    expect(report.dateText, '10 نوفمبر 2026');
    expect(report.address, 'حي العليا');
    expect(report.latitude, 24.7);
    expect(report.longitude, 46.6);
    expect(report.issueClass, 'curb_ramp_issue');
    expect(report.severity, isNull);

    final bare = CitizenReport.fromMap('r2', {});
    expect(bare.dateText, CitizenReport.noDate);
    expect(bare.address, isNull);
  });

  test('issue class and severity labels', () {
    expect(issueClassLabel('surface_damage'), 'تضرر سطح الرصيف');
    expect(issueClassLabel('curb_ramp_issue'), 'مشكلة في منحدر الرصيف');
    expect(issueClassLabel(null), unknownIssueClass);
    expect(severityLabel('severe'), 'عالية');
    expect(severityLabel('high'), 'عالية');
    expect(severityLabel('non_severe'), 'منخفضة إلى متوسطة');
    expect(severityLabel(null), unknownSeverity);
    expect(isSevere('HIGH'), isTrue);
    expect(isSevere('non_severe'), isFalse);
  });

  group('My Reports', () {
    testWidgets('lists newest first with date and place, and filters', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        host(ReportsScreen(reports: Stream.value([older, newest, middle]))),
      );
      await tester.pumpAndSettle();

      // Newest to oldest.
      final first = topOf(tester, 'بلاغ KHT-BBBBBBBB');
      final second = topOf(tester, 'بلاغ KHT-CCCCCCCC');
      final third = topOf(tester, 'بلاغ KHT-AAAAAAAA');
      expect(first, lessThan(second));
      expect(second, lessThan(third));

      // Date and place on each card, in the home card format.
      expect(find.text('10 نوفمبر 2026'), findsOneWidget);
      expect(find.text('20 أكتوبر 2026'), findsOneWidget);
      expect(find.text('1 أكتوبر 2026'), findsOneWidget);
      expect(find.text('حي العليا، طريق الملك فهد'), findsOneWidget);
      expect(find.text('حي النرجس'), findsOneWidget);
      expect(find.text('حي الملقا'), findsOneWidget);

      // Status filters still work.
      await tester.tap(
        find.widgetWithText(ChoiceChip, ReportStatusLabels.pending),
      );
      await tester.pumpAndSettle();
      expect(find.text('بلاغ KHT-BBBBBBBB'), findsOneWidget);
      expect(find.text('بلاغ KHT-AAAAAAAA'), findsNothing);
      expect(find.text('بلاغ KHT-CCCCCCCC'), findsNothing);
    });

    testWidgets('updates when the stream sends new reports', (tester) async {
      final controller = StreamController<List<CitizenReport>>();
      addTearDown(controller.close);
      await tester.pumpWidget(host(ReportsScreen(reports: controller.stream)));

      controller.add([older]);
      await tester.pumpAndSettle();
      expect(find.text('بلاغ KHT-AAAAAAAA'), findsOneWidget);
      expect(find.text('بلاغ KHT-BBBBBBBB'), findsNothing);

      controller.add([older, newest]);
      await tester.pumpAndSettle();
      expect(find.text('بلاغ KHT-BBBBBBBB'), findsOneWidget);
    });

    testWidgets('tapping a report opens the details page, not a sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(ReportsScreen(reports: Stream.value([newest]))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('بلاغ KHT-BBBBBBBB'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportDetailsScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('تفاصيل البلاغ'), findsOneWidget);
      expect(find.text('KHT-BBBBBBBB'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ReportDetailsScreen), findsNothing);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('list fits 320px RTL at scale $scale', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(
            ReportsScreen(reports: Stream.value([older, newest, middle])),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Report details', () {
    testWidgets('shows date, place, both statuses, and analysis results', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(host(ReportDetailsScreen(report: older)));
      await tester.pumpAndSettle();

      expect(find.text('KHT-AAAAAAAA'), findsOneWidget);
      expect(find.text('بلاغ قديم'), findsOneWidget);
      expect(find.text('1 أكتوبر 2026'), findsOneWidget);
      expect(find.text('حي الملقا'), findsOneWidget);
      expect(find.text('تضرر سطح الرصيف'), findsOneWidget);
      expect(find.text('عالية'), findsOneWidget);
      // Analysis and report status are shown separately.
      expect(find.text('حالة تحليل الصورة'), findsOneWidget);
      expect(find.text('اكتمل تحليل الصورة'), findsOneWidget);
      expect(find.text('حالة البلاغ'), findsOneWidget);
      expect(find.text(ReportStatusLabels.resolved), findsOneWidget);
    });

    testWidgets('shows "unspecified" before the analysis result exists', (
      tester,
    ) async {
      await tester.pumpWidget(host(ReportDetailsScreen(report: newest)));
      await tester.pumpAndSettle();
      expect(find.text(unknownIssueClass), findsOneWidget);
      expect(find.text(unknownSeverity), findsOneWidget);
      expect(find.text(CitizenReport.noDate), findsNothing);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('fits 320px in ${mode.name} mode at scale $scale', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(const Size(320, 2000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            host(
              ReportDetailsScreen(report: older, demo: true),
              mode: mode,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text('هذا بلاغ تجريبي وليس بلاغًا حقيقيًا.'),
            findsOneWidget,
          );
        });
      }
    }
  });

  group('Map markers', () {
    test('colour follows the report status', () {
      expect(
        ReportMarkerColors.forStatus('pending'),
        ReportMarkerColors.pending,
      );
      expect(
        ReportMarkerColors.forStatus('in_progress'),
        ReportMarkerColors.inProgress,
      );
      expect(
        ReportMarkerColors.forStatus('resolved'),
        ReportMarkerColors.resolved,
      );
      expect(ReportMarkerColors.forStatus(null), ReportMarkerColors.unknown);
      expect(
        {
          ReportMarkerColors.pending,
          ReportMarkerColors.inProgress,
          ReportMarkerColors.resolved,
          ReportMarkerColors.unknown,
        }.length,
        4,
      );
    });

    Future<IconButton> pumpMarker(
      WidgetTester tester, {
      required Object? status,
      required Object? severity,
      VoidCallback? onPressed,
    }) async {
      await tester.pumpWidget(
        host(
          Center(
            child: ReportMapMarker(
              reportStatus: status,
              severity: severity,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      );
      return tester.widget<IconButton>(find.byType(IconButton));
    }

    Color? background(WidgetTester tester, IconButton button) =>
        button.style!.backgroundColor!.resolve({});
    BorderSide? side(IconButton button) => button.style!.side!.resolve({});

    testWidgets('normal severity uses the pin and a thin white border', (
      tester,
    ) async {
      final button = await pumpMarker(
        tester,
        status: 'in_progress',
        severity: 'non_severe',
      );
      expect(background(tester, button), ReportMarkerColors.inProgress);
      expect(find.byIcon(ReportMapMarker.normalIcon), findsOneWidget);
      expect(find.byIcon(ReportMapMarker.severeIcon), findsNothing);
      expect(side(button)!.color, Colors.white);
      expect(side(button)!.width, 2);
    });

    testWidgets('high severity uses the warning icon and a red border', (
      tester,
    ) async {
      var taps = 0;
      final button = await pumpMarker(
        tester,
        status: 'pending',
        severity: 'severe',
        onPressed: () => taps++,
      );
      expect(background(tester, button), ReportMarkerColors.pending);
      expect(find.byIcon(ReportMapMarker.severeIcon), findsOneWidget);
      expect(find.byIcon(ReportMapMarker.normalIcon), findsNothing);
      expect(side(button)!.color, AppColors.error);
      expect(side(button)!.width, 3);

      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('legend lists the three statuses and high severity '
          '(${mode.name})', (tester) async {
        await tester.pumpWidget(
          host(const Center(child: ReportMapLegend()), mode: mode),
        );
        expect(find.text(ReportStatusLabels.pending), findsOneWidget);
        expect(find.text('قيد التنفيذ'), findsOneWidget);
        expect(find.text(ReportStatusLabels.resolved), findsOneWidget);
        expect(find.text('شدة عالية'), findsOneWidget);
        expect(find.byIcon(ReportMapMarker.severeIcon), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
