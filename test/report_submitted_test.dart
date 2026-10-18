import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/models/report_location.dart';
import 'package:khota_app/models/submitted_report.dart';
import 'package:khota_app/screens/reports/report_submitted_screen.dart';

void main() {
  test('date is formatted with the Arabic month name', () {
    expect(
      ReportSubmittedScreen.formatDate(DateTime(2026, 10, 18)),
      '18 أكتوبر 2026',
    );
  });

  for (final openReports in [true, false]) {
    testWidgets('shows number, two statuses and next steps; '
        'openReports=$openReports', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('open'),
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ReportSubmittedScreen(
                        now: DateTime(2026, 10, 18),
                        report: const SubmittedReport(
                          id: 'abCD12efGH34ijKL56mn',
                          address: 'حي النرجس',
                          location: ReportLocation(
                            latitude: 24.7,
                            longitude: 46.6,
                            source: ReportLocation.sourceGps,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('تم استلام بلاغك'), findsOneWidget);
      expect(find.text('KHT-ABCD12EF'), findsOneWidget);
      expect(find.text('حي النرجس'), findsOneWidget);
      expect(find.text('18 أكتوبر 2026'), findsOneWidget);
      // Report status and image analysis are shown separately.
      expect(find.text('حالة البلاغ'), findsOneWidget);
      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(find.text('جارٍ تحليل الصورة'), findsOneWidget);
      expect(find.text('معالجة البلاغ من الجهة المختصة'), findsOneWidget);
      await tester.tap(
        find.text(openReports ? 'متابعة بلاغاتي' : 'العودة للرئيسية'),
      );
      await tester.pumpAndSettle();
      expect(result, openReports);
    });
  }
}
