import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/khota_colors.dart';
import '../utils/report_labels.dart';
import 'report_status_widgets.dart';

/// Marker colours by report status. The map tiles are light in both themes,
/// so the same colours are used in light and dark mode.
class ReportMarkerColors {
  ReportMarkerColors._();

  static const pending = AppColors.amber;
  static const inProgress = AppColors.gradientTop;
  static const resolved = AppColors.greenDeep;
  static const unknown = Color(0xFF6B7470);

  /// Colour for a `mapReports` status: pending / in_progress / resolved.
  static Color forStatus(Object? status) => switch (status) {
    'pending' => pending,
    'in_progress' => inProgress,
    'resolved' => resolved,
    _ => unknown,
  };
}

/// One report on the map: coloured by status, with a warning icon and a red
/// border when the severity is high.
class ReportMapMarker extends StatelessWidget {
  const ReportMapMarker({
    super.key,
    required this.reportStatus,
    required this.severity,
    required this.onPressed,
  });

  final Object? reportStatus;
  final Object? severity;
  final VoidCallback onPressed;

  static const normalIcon = Icons.location_on_rounded;
  static const severeIcon = Icons.warning_rounded;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final severe = isSevere(severity);

    return IconButton(
      tooltip: 'عرض ملخص البلاغ',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: ReportMarkerColors.forStatus(reportStatus),
        foregroundColor: Colors.white,
        side: BorderSide(
          color: severe
              ? AppColors.error
              : colors.isDark
              ? colors.background
              : Colors.white,
          width: severe ? 3 : 2,
        ),
      ),
      icon: Icon(severe ? severeIcon : normalIcon, size: 25),
    );
  }
}

/// Small key for the marker colours and the high-severity icon.
class ReportMapLegend extends StatelessWidget {
  const ReportMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelSmall;

    Widget row(Widget mark, String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 16, child: Center(child: mark)),
          const SizedBox(width: 6),
          Text(label, style: text),
        ],
      ),
    );

    Widget dot(Color color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Semantics(
      container: true,
      label: 'دليل ألوان الخريطة',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(dot(ReportMarkerColors.pending), ReportStatusLabels.pending),
              row(
                dot(ReportMarkerColors.inProgress),
                ReportStatusLabels.short(ReportStatusLabels.inProgress),
              ),
              row(
                dot(ReportMarkerColors.resolved),
                ReportStatusLabels.resolved,
              ),
              row(
                const Icon(
                  ReportMapMarker.severeIcon,
                  size: 16,
                  color: AppColors.error,
                ),
                'شدة عالية',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
