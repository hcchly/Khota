
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khota_app/screens/info/photo_guide_screen.dart';
import 'package:khota_app/widgets/report_status_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All eight photo guide images are available', () async {
    const images = [
      'angle_good.jpg',
      'angle_bad.jpg',
      'distance_good.jpg',
      'distance_bad.jpg',
      'lighting_good.jpg',
      'lighting_bad.jpg',
      'clarity_good.jpg',
      'clarity_bad.jpg',
    ];

    for (final image in images) {
      final data = await rootBundle.load('assets/images/$image');
      expect(data.lengthInBytes, greaterThan(0));
    }
  });

  testWidgets('Photo guide displays photography instructions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PhotoGuideScreen()),
    );

    expect(find.text('دليل التصوير'), findsOneWidget);
    expect(
      find.textContaining('زاوية التصوير'),
      findsOneWidget,
    );
  });

  testWidgets('Analysis and report statuses are separate',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportStatusSummary(
            analysisStatus: ReportStatusLabels.analyzing,
            reportStatus: ReportStatusLabels.pending,
          ),
        ),
      ),
    );

    expect(find.text('حالة تحليل الصورة'), findsOneWidget);
    expect(find.text('حالة البلاغ'), findsOneWidget);
    expect(
      find.text(ReportStatusLabels.analyzing),
      findsOneWidget,
    );
    expect(
      find.text(ReportStatusLabels.pending),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportStatusSummary(
            analysisStatus: ReportStatusLabels.analyzing,
            reportStatus: ReportStatusLabels.resolved,
          ),
        ),
      ),
    );

    expect(
      find.text(ReportStatusLabels.resolved),
      findsOneWidget,
    );
    expect(
      find.text(ReportStatusLabels.analyzing),
      findsOneWidget,
    );
  });

  testWidgets('Report filters update selected status',
      (tester) async {
    String selected = 'الكل';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ReportStatusFilters(
                selectedFilter: selected,
                onFilterChanged: (value) {
                  setState(() => selected = value);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(4));

    final resolved = find.widgetWithText(
      ChoiceChip,
      ReportStatusLabels.resolved,
    );

    await tester.tap(resolved);
    await tester.pump();

    expect(selected, ReportStatusLabels.resolved);
    expect(
      tester.widget<ChoiceChip>(resolved).selected,
      isTrue,
    );
  });
}
