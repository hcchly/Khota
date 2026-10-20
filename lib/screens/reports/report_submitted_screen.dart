import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/submitted_report.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/info_card.dart';
import '../../widgets/report_card.dart';

/// Shown after a report has been saved: report number, a summary with the
/// two separate statuses, and what happens next.
///
/// Pops with `true` when the citizen chooses "متابعة بلاغاتي", and `false`
/// (or null with the back gesture) to return to the home screen.
class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({super.key, required this.report, this.now});

  final SubmittedReport report;

  /// Submission date shown in the summary; defaults to today.
  final DateTime? now;

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static String formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = AppColors.indigo.withValues(alpha: 0.65);
    final number = ReportService.displayNumber(report.id);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
              children: [
                // Success.
                Semantics(
                  liveRegion: true,
                  label: 'تم استلام بلاغك. رقم البلاغ $number',
                  child: Column(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'تم استلام بلاغك',
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Report number with copy.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableText(
                            number,
                            textDirection: TextDirection.ltr,
                            style: text.titleMedium?.copyWith(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          IconButton(
                            tooltip: 'نسخ رقم البلاغ',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            color: AppColors.teal,
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: number),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ رقم البلاغ'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        'احتفظ برقم البلاغ لمتابعته لاحقاً.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Summary: location, date and the two separate statuses.
                InfoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              report.address ??
                                  report.location.coordinatesText,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDate(now ?? DateTime.now()),
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: 'حالة البلاغ',
                        child: StatusChip.reportStatus('pending'),
                      ),
                      const SizedBox(height: 10),
                      const _SummaryRow(
                        label: 'تحليل الصورة',
                        child: AnalysisStatusLine(status: 'processing'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Next steps: image analysis and the authority's handling are
                // two different stages, so they are described separately.
                InfoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ماذا يحدث بعد ذلك؟',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _NextStep(
                        number: 1,
                        title: 'تحليل الصورة',
                        body:
                            'يحلّل النظام الصورة تلقائياً لتحديد نوع المشكلة ومستوى خطورتها.',
                      ),
                      const _NextStep(
                        number: 2,
                        title: 'معالجة البلاغ من الجهة المختصة',
                        body:
                            'تراجع الجهة المختصة البلاغ وتحدّث حالته: قيد الانتظار، ثم قيد التنفيذ، ثم تم الحل.',
                      ),
                      const _NextStep(
                        number: 3,
                        title: 'المتابعة',
                        body:
                            'تابع حالة تحليل الصورة وحالة البلاغ من «بلاغاتي».',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('متابعة بلاغاتي'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.indigo.withValues(alpha: 0.65),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'الخطوة $number: $title. $body',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.indigo,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.indigo.withValues(alpha: 0.7),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
