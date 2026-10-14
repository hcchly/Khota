import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/models/report_draft.dart';
import 'package:khota_app/screens/reports/report_photo_screen.dart';

import 'report_photo_test.dart' show FakeCamera;

final photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9l8AAAAASUVORK5CYII=',
);

void main() {
  for (final cached in [false, true]) {
    testWidgets('save returns URL; cached=$cached', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ReportDraft? result;
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('open'),
                onPressed: () async {
                  result = await Navigator.of(context).push<ReportDraft>(
                    MaterialPageRoute(
                      builder: (_) => ReportPhotoScreen(
                        initialDraft: ReportDraft(
                          imageBytes: photo,
                          description: 'وصف',
                          imageUrl: cached
                              ? 'https://example.test/image'
                              : null,
                        ),
                        camera: FakeCamera(),
                        uploadImage: (bytes) async {
                          calls++;
                          expect(bytes, photo);
                          return 'https://example.test/image';
                        },
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
      await tester.tap(find.text('حفظ الصورة والتفاصيل'));
      await tester.pumpAndSettle();
      expect(result?.imageUrl, 'https://example.test/image');
      expect(result?.description, 'وصف');
      expect(calls, cached ? 0 : 1);
      expect(find.text('open'), findsOneWidget);
    });
  }

  testWidgets(
    'pending upload disables save; failure retains input and permits retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pending = Completer<String>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ReportPhotoScreen(
            initialDraft: ReportDraft(
              imageBytes: photo,
              description: 'يبقى الوصف',
            ),
            camera: FakeCamera(),
            uploadImage: (_) {
              calls++;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ الصورة والتفاصيل'));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'جارٍ رفع الصورة…'),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 1);
      pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تعذّر رفع الصورة'), findsWidgets);
      expect(find.text('يبقى الوصف'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'حفظ الصورة والتفاصيل'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
