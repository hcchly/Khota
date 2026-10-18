import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/models/report_draft.dart';
import 'package:khota_app/models/report_location.dart';
import 'package:khota_app/models/submitted_report.dart';
import 'package:khota_app/screens/reports/new_report_screen.dart';
import 'package:khota_app/services/report_service.dart';

import 'helpers/report_fakes.dart';

Future<void> _pump(
  WidgetTester tester,
  NewReportScreen screen, {
  void Function(SubmittedReport?)? onResult,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            child: const Text('open'),
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<SubmittedReport>(
                    MaterialPageRoute(builder: (_) => screen),
                  );
              onResult?.call(result);
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _button(String label) => find.widgetWithText(ElevatedButton, label);

void main() {
  test('report number format', () {
    expect(ReportService.shortCode('abCD12efGH34ijKL56mn'), 'ABCD12EF');
    expect(
      ReportService.displayNumber('abCD12efGH34ijKL56mn'),
      'KHT-ABCD12EF',
    );
    expect(ReportService.generateId().length, 20);
    expect(ReportService.generateId(), isNot(ReportService.generateId()));
  });

  test('new report starts as pending and processing with no result', () {
    final fields = ReportService.newReportFields(
      userId: 'u1',
      draft: ReportDraft(
        imageBytes: testPhoto,
        description: ' وصف ',
        imageUrl: 'https://example.test/image',
      ),
      location: FakeLocationProvider.gpsGood,
    );
    expect(fields['userId'], 'u1');
    expect(fields['description'], 'وصف');
    expect(fields['locationSource'], 'gps');
    expect(fields['locationAccuracyMeters'], 12);
    expect(fields['reportStatus'], 'pending');
    expect(fields['analysisStatus'], 'processing');
    expect(fields['issueClass'], isNull);
    expect(fields['severity'], isNull);
  });

  testWidgets('step 1: capture shows preview with retake and gallery', (
    tester,
  ) async {
    final camera = FakeCamera();
    await _pump(tester, NewReportScreen(camera: camera));
    expect(find.text('التقاط صورة'), findsOneWidget);
    expect(find.text('اختيار من المعرض'), findsOneWidget);
    await tester.tap(find.text('التقاط صورة'));
    await tester.pumpAndSettle();
    expect(find.text('معاينة الصورة'), findsOneWidget);
    expect(_button('استخدام الصورة'), findsOneWidget);
    expect(find.text('إعادة التصوير'), findsOneWidget);
    await tester.tap(find.text('من المعرض'));
    await tester.pumpAndSettle();
    expect(camera.galleryCalls, 1);
  });

  testWidgets('step 1: camera failure shows a recoverable error', (
    tester,
  ) async {
    await _pump(tester, NewReportScreen(camera: FakeCamera()..fail = true));
    await tester.tap(find.text('التقاط صورة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تحقّق من إذن الكاميرا'), findsOneWidget);
    expect(_button('استخدام الصورة'), findsNothing);
  });

  testWidgets('full flow: photo, location with accuracy, details, send', (
    tester,
  ) async {
    SubmittedReport? result;
    var uploads = 0;
    ReportDraft? saved;
    await _pump(
      tester,
      NewReportScreen(
        initialDraft: ReportDraft(imageBytes: testPhoto),
        camera: FakeCamera(),
        locationProvider: FakeLocationProvider(address: 'حي النرجس'),
        uploadImage: (_) async {
          uploads++;
          return 'https://example.test/image';
        },
        submitReport: (id, draft, location) async {
          expect(id.length, 20);
          expect(location.source, 'gps');
          saved = draft;
        },
      ),
      onResult: (r) => result = r,
    );

    await tester.tap(_button('استخدام الصورة'));
    await tester.pumpAndSettle();
    expect(find.text('دقة عالية · ± 12 م'), findsOneWidget);
    expect(find.text('حي النرجس'), findsWidgets);

    await tester.tap(_button('تأكيد الموقع'));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة وإرسال'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'رصيف مكسور');

    await tester.tap(_button('إرسال البلاغ'));
    await tester.pumpAndSettle();
    expect(uploads, 1);
    expect(saved?.description, 'رصيف مكسور');
    expect(saved?.imageUrl, 'https://example.test/image');
    expect(result?.address, 'حي النرجس');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('back from review returns to the location step', (tester) async {
    await _pump(
      tester,
      NewReportScreen(
        initialDraft: ReportDraft(imageBytes: testPhoto),
        camera: FakeCamera(),
        locationProvider: FakeLocationProvider(),
        uploadImage: (_) async => 'u',
        submitReport: (_, _, _) async {},
      ),
    );
    await tester.tap(_button('استخدام الصورة'));
    await tester.pumpAndSettle();
    await tester.tap(_button('تأكيد الموقع'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(_button('تأكيد الموقع'), findsOneWidget);
  });

  testWidgets('low GPS accuracy shows a hint', (tester) async {
    await _pump(
      tester,
      NewReportScreen(
        initialDraft: ReportDraft(imageBytes: testPhoto),
        camera: FakeCamera(),
        locationProvider: FakeLocationProvider(
          location: const ReportLocation(
            latitude: 24.7,
            longitude: 46.6,
            source: ReportLocation.sourceGps,
            accuracyMeters: 120,
          ),
        ),
      ),
    );
    await tester.tap(_button('استخدام الصورة'));
    await tester.pumpAndSettle();
    expect(find.text('دقة منخفضة · ± 120 م'), findsOneWidget);
    expect(find.textContaining('حدّد الموقع يدوياً'), findsOneWidget);
  });

  testWidgets('no location: error shown and confirm disabled', (tester) async {
    await _pump(
      tester,
      NewReportScreen(
        initialDraft: ReportDraft(imageBytes: testPhoto),
        camera: FakeCamera(),
        locationProvider: FakeLocationProvider(location: null),
      ),
    );
    await tester.tap(_button('استخدام الصورة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر تحديد موقعك'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(_button('تأكيد الموقع')).onPressed,
      isNull,
    );
  });

  testWidgets('upload failure keeps details and allows retry', (tester) async {
    final pending = Completer<String>();
    var calls = 0;
    await _pump(
      tester,
      NewReportScreen(
        initialDraft: ReportDraft(imageBytes: testPhoto, description: 'يبقى'),
        camera: FakeCamera(),
        locationProvider: FakeLocationProvider(),
        uploadImage: (_) {
          calls++;
          return pending.future;
        },
        submitReport: (_, _, _) async {},
      ),
    );
    await tester.tap(_button('استخدام الصورة'));
    await tester.pumpAndSettle();
    await tester.tap(_button('تأكيد الموقع'));
    await tester.pumpAndSettle();
    await tester.tap(_button('إرسال البلاغ'));
    await tester.pump();
    expect(find.text('جارٍ إرسال البلاغ…'), findsOneWidget);
    expect(calls, 1);
    pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر رفع الصورة'), findsOneWidget);
    expect(find.text('يبقى'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(_button('إعادة المحاولة')).onPressed,
      isNotNull,
    );
  });

  testWidgets('save failure reuses the uploaded photo and the same ID', (
    tester,
  ) async {
    var uploads = 0;
    final ids = <String>[];
    var failSave = true;
    SubmittedReport? result;
    await _pump(
      tester,
      NewReportScreen(
        initialDraft: ReportDraft(imageBytes: testPhoto),
        camera: FakeCamera(),
        locationProvider: FakeLocationProvider(),
        uploadImage: (_) async {
          uploads++;
          return 'https://example.test/image';
        },
        submitReport: (id, _, _) async {
          ids.add(id);
          if (failSave) throw Exception('offline');
        },
      ),
      onResult: (r) => result = r,
    );
    await tester.tap(_button('استخدام الصورة'));
    await tester.pumpAndSettle();
    await tester.tap(_button('تأكيد الموقع'));
    await tester.pumpAndSettle();
    await tester.tap(_button('إرسال البلاغ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر حفظ البلاغ'), findsOneWidget);
    failSave = false;
    await tester.tap(_button('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(uploads, 1);
    expect(ids, hasLength(2));
    expect(ids[0], ids[1]);
    expect(result?.id, ids[0]);
  });
}
