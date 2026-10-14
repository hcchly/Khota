import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khota_app/models/report_draft.dart';
import 'package:khota_app/screens/reports/report_photo_screen.dart';
import 'package:khota_app/services/report_camera_service.dart';

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9l8AAAAASUVORK5CYII=',
);

class FakeCamera implements ReportCameraService {
  Uint8List? next = _pixel;
  bool fail = false;
  @override
  Future<Uint8List?> capture() async {
    if (fail) throw Exception('permission denied');
    return next;
  }

  @override
  Future<Uint8List?> recover() async => null;
}

void main() {
  test('description is optional and serialized without photo bytes', () {
    expect(ReportDraft(imageBytes: _pixel).toFirestoreFields(), {
      'description': '',
    });
    expect(
      ReportDraft(
        imageBytes: _pixel,
        description: '  رصيف مكسور  ',
      ).toFirestoreFields(),
      {'description': 'رصيف مكسور'},
    );
  });

  testWidgets(
    'preview requires acceptance; retake cancellation retains photo and description',
    (tester) async {
      final camera = FakeCamera();
      await tester.pumpWidget(
        MaterialApp(home: ReportPhotoScreen(camera: camera)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(find.text('التقاط صورة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('التقاط صورة'));
      await tester.pumpAndSettle();
      expect(find.text('إعادة التصوير'), findsOneWidget);
      expect(find.text('استخدام الصورة'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(find.text('استخدام الصورة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('استخدام الصورة'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'رصيف مكسور');
      camera.next = null;
      await tester.ensureVisible(find.text('إعادة التصوير'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إعادة التصوير'));
      await tester.pumpAndSettle();
      expect(find.text('رصيف مكسور'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      camera.next = _pixel;
      await tester.tap(find.text('إعادة التصوير'));
      await tester.pumpAndSettle();
      expect(find.text('استخدام الصورة'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('camera failure shows recoverable error', (tester) async {
    final camera = FakeCamera()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: ReportPhotoScreen(camera: camera)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('التقاط صورة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التقاط صورة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تحقّق من إذن الكاميرا'), findsOneWidget);
    expect(find.text('استخدام الصورة'), findsNothing);
  });
}
