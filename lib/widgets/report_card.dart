import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'report_status_widgets.dart';
import 'private_report_image.dart';

/// Colour family of a [StatusChip].
enum StatusTone { neutral, progress, success, info, warning }

/// Small rounded label, e.g. "قيد الانتظار".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  /// Chip for the report status set by the authority
  /// (pending / in progress / resolved).
  factory StatusChip.reportStatus(String status, {Key? key}) {
    switch (status.trim().toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
      case 'in progress':
        return StatusChip(
          key: key,
          label: 'قيد التنفيذ',
          tone: StatusTone.progress,
        );
      case 'resolved':
        return StatusChip(
          key: key,
          label: ReportStatusLabels.resolved,
          tone: StatusTone.success,
        );
      default:
        return StatusChip(
          key: key,
          label: ReportStatusLabels.pending,
          tone: StatusTone.neutral,
        );
    }
  }

  (Color, Color) get _colors {
    switch (tone) {
      case StatusTone.progress:
        return (const Color(0xFFFBEFD5), const Color(0xFF8A5A00));
      case StatusTone.success:
        return (AppColors.teal.withValues(alpha: 0.15), AppColors.teal);
      case StatusTone.info:
        return (AppColors.indigo.withValues(alpha: 0.10), AppColors.indigo);
      case StatusTone.warning:
        return (AppColors.error.withValues(alpha: 0.10), AppColors.error);
      case StatusTone.neutral:
        return (AppColors.slate.withValues(alpha: 0.45), AppColors.indigo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One line describing the automatic image analysis.
/// Kept separate from report status so image analysis
/// is not confused with authority report handling.
class AnalysisStatusLine extends StatelessWidget {
  const AnalysisStatusLine({super.key, required this.status});

  /// processing / completed / not_assessable
  final String status;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label, Color color) = switch (status
        .trim()
        .toLowerCase()) {
      'completed' || 'done' => (
        Icons.check_circle_outline,
        'اكتمل تحليل الصورة',
        AppColors.teal,
      ),
      'not_assessable' ||
      'notassessable' ||
      'failed' => (Icons.error_outline, 'تعذّر تقييم الصورة', AppColors.error),
      _ => (
        Icons.hourglass_top_rounded,
        ReportStatusLabels.analyzing,
        AppColors.indigo.withValues(alpha: 0.7),
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    );
  }
}

/// A report in a list (home "آخر البلاغات"
/// and the reports tab).
///
/// Display only: the caller provides the data
/// and the tap action.
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.title,
    required this.locationText,
    required this.dateText,
    required this.reportStatus,
    required this.analysisStatus,
    this.reportNumber,
    this.imageUrl,
    this.onTap,
  });

  /// e.g. "تلف في سطح الرصيف",
  /// or "بلاغ جديد" before analysis.
  final String title;
  final String locationText;
  final String dateText;
  final String reportStatus;
  final String analysisStatus;
  final String? reportNumber;

  /// Private Firebase Storage path for new reports.
  final String? imageUrl;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final muted = AppColors.indigo.withValues(alpha: 0.6);

    final radius = BorderRadius.circular(24);
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.ocean.withValues(alpha: 0.07)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: imageUrl == null
                          ? const _ThumbPlaceholder()
                          : PrivateReportImage(
                              imageRef: imageUrl!,
                              height: 62,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reportNumber != null)
                          Text(
                            reportNumber!,
                            textDirection: TextDirection.ltr,
                            style: text.labelSmall?.copyWith(
                              color: AppColors.ocean,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip.reportStatus(reportStatus),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                locationText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 9),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  AnalysisStatusLine(status: analysisStatus),
                  Text(
                    dateText,
                    style: text.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.sand,
      child: Icon(
        Icons.photo_camera_outlined,
        color: AppColors.slate.withValues(alpha: 0.9),
      ),
    );
  }
}
