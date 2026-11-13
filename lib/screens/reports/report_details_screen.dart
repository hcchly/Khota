import 'package:flutter/material.dart';

import '../../models/citizen_report.dart';
import '../../services/report_service.dart';
import '../../theme/khota_colors.dart';
import '../../utils/report_labels.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/place_name.dart';
import '../../widgets/private_report_image.dart';
import '../../widgets/report_status_widgets.dart';

/// Full details of one of the citizen's reports, opened from "بلاغاتي".
class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({
    super.key,
    required this.report,
    this.demo = false,
  });

  final CitizenReport report;

  /// True for the preview examples, which are not real reports.
  final bool demo;

  /// Same number as the submission confirmation and the list.
  static String displayNumber(String id) =>
      id.startsWith('DEMO-') ? id : ReportService.displayNumber(id);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;

    return Scaffold(
      appBar: const GradientAppBar(title: 'تفاصيل البلاغ'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(
                  displayNumber(report.id),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: text.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.description,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Private image: downloaded only for its owner.
                if (report.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ColoredBox(
                      color: colors.surfaceSunken,
                      child: SizedBox(
                        width: double.infinity,
                        child: PrivateReportImage(
                          imageRef: report.imageUrl!,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                InfoCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ البلاغ',
                        child: Text(report.dateText),
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'الموقع',
                        child: PlaceName(
                          address: report.address,
                          latitude: report.latitude,
                          longitude: report.longitude,
                          maxLines: 3,
                        ),
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.category_outlined,
                        label: 'نوع المشكلة',
                        child: Text(issueClassLabel(report.issueClass)),
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.speed_outlined,
                        label: 'الشدة',
                        child: Text(severityLabel(report.severity)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Image analysis and report status are two separate processes.
                ReportStatusSummary(
                  analysisStatus: report.analysisStatus,
                  reportStatus: report.reportStatus,
                ),

                if (demo) ...[
                  const SizedBox(height: 16),
                  const Text('هذا بلاغ تجريبي وليس بلاغًا حقيقيًا.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.bodySmall?.copyWith(color: colors.muted(0.65)),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
