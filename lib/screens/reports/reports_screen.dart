import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/info_card.dart';
import '../../widgets/brand_surface.dart';
import '../../widgets/private_report_image.dart';
import '../../widgets/report_status_widgets.dart';

class CitizenReport {
  const CitizenReport({
    required this.id,
    required this.description,
    required this.reportStatus,
    required this.analysisStatus,
    this.imageUrl,
  });

  final String id;
  final String description;
  final String reportStatus;
  final String analysisStatus;

  // New reports store a private Firebase Storage path.
  final String? imageUrl;

  static String reportLabel(dynamic value) {
    final s = (value ?? '').toString().trim().toLowerCase();

    if (s == 'pending' || s == 'قيد الانتظار') {
      return ReportStatusLabels.pending;
    }

    if (s == 'inprogress' ||
        s == 'in_progress' ||
        s == 'in progress' ||
        s == 'قيد التنفيذ من الجهة المختصة') {
      return ReportStatusLabels.inProgress;
    }

    if (s == 'resolved' || s == 'completed' || s == 'done' || s == 'تم الحل') {
      return ReportStatusLabels.resolved;
    }

    return 'حالة البلاغ غير متاحة';
  }

  static String analysisLabel(dynamic value) {
    final s = (value ?? '').toString().trim().toLowerCase();

    if (s == 'processing' || s == 'analyzing' || s == 'جارٍ تحليل الصورة') {
      return ReportStatusLabels.analyzing;
    }

    if (s == 'completed' || s == 'done') {
      return 'اكتمل تحليل الصورة';
    }

    if (s == 'failed' || s == 'not_assessable' || s == 'notassessable') {
      return 'تعذّر تحليل الصورة';
    }

    return 'حالة التحليل غير متاحة';
  }

  factory CitizenReport.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final description = (data['description'] ?? '').toString().trim();

    final image = data['imageUrl'];

    return CitizenReport(
      id: doc.id,
      description: description.isEmpty
          ? 'بلاغ عن مشكلة في الرصيف'
          : description,
      reportStatus: reportLabel(data['reportStatus'] ?? data['status']),
      analysisStatus: analysisLabel(
        data['analysisStatus'] ?? data['imageAnalysisStatus'],
      ),
      imageUrl: image is String && image.isNotEmpty ? image : null,
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.initialPreview = false});

  final bool initialPreview;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedFilter = 'الكل';

  late bool previewMode = widget.initialPreview;

  // Demo reports are for UI preview only.
  // They are not real citizen reports.
  static const sampleReports = <CitizenReport>[
    CitizenReport(
      id: 'DEMO-01',
      description: 'بلاط رصيف مكسور',
      reportStatus: ReportStatusLabels.pending,
      analysisStatus: ReportStatusLabels.analyzing,
    ),
    CitizenReport(
      id: 'DEMO-02',
      description: 'منحدر رصيف يحتاج إلى صيانة',
      reportStatus: ReportStatusLabels.inProgress,
      analysisStatus: 'اكتمل تحليل الصورة',
    ),
    CitizenReport(
      id: 'DEMO-03',
      description: 'رصيف مائل قرب ممر مشاة',
      reportStatus: ReportStatusLabels.resolved,
      analysisStatus: 'اكتمل تحليل الصورة',
    ),
  ];

  // Display the same report number used after submission.
  String displayReportNumber(String id) {
    if (id.startsWith('DEMO-')) {
      return id;
    }

    return ReportService.displayNumber(id);
  }

  // Open report details.
  void openDetails(CitizenReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل البلاغ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                Text('رقم البلاغ: ${displayReportNumber(report.id)}'),

                const SizedBox(height: 12),

                Text(report.description),

                // Load private image through Firebase Storage.
                if (report.imageUrl != null) ...[
                  const SizedBox(height: 16),

                  PrivateReportImage(
                    imageRef: report.imageUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ],

                const SizedBox(height: 20),

                // Image analysis and report status
                // are two separate processes.
                ReportStatusSummary(
                  analysisStatus: report.analysisStatus,
                  reportStatus: report.reportStatus,
                ),

                if (previewMode) ...[
                  const SizedBox(height: 16),
                  const Text('هذا بلاغ تجريبي وليس بلاغًا حقيقيًا.'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Activate preview mode.
  Widget previewButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          previewMode = true;
          selectedFilter = 'الكل';
        });
      },
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('معاينة الحالات والفلاتر'),
    );
  }

  // Build reports according to selected filter.
  Widget buildReportList(List<CitizenReport> reports) {
    final filtered = selectedFilter == ReportStatusLabels.all
        ? reports
        : reports
              .where((report) => report.reportStatus == selectedFilter)
              .toList();

    final counts = {
      for (final filter in ReportStatusLabels.filters)
        filter: filter == ReportStatusLabels.all
            ? reports.length
            : reports.where((r) => r.reportStatus == filter).length,
    };

    // Four filters in one sliding row: All, Pending, In Progress, Resolved.
    final filters = reports.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ReportStatusFilters(
              selectedFilter: selectedFilter,
              counts: counts,
              onFilterChanged: (value) =>
                  setState(() => selectedFilter = value),
            ),
          );

    if (filtered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [filters, _emptyState(reports)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [filters, _reportCards(filtered)],
    );
  }

  Widget _emptyState(List<CitizenReport> reports) {
    return InfoCard(
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: context.khota.primary),

          const SizedBox(height: 12),

          Text(
            reports.isEmpty
                ? 'لا توجد بلاغات بعد'
                : 'لا توجد بلاغات بهذه الحالة',
          ),

          if (reports.isEmpty && !previewMode) ...[
            const SizedBox(height: 12),
            if (kDebugMode) previewButton(),
          ],
        ],
      ),
    );
  }

  Widget _reportCards(List<CitizenReport> filtered) {
    return Column(
      children: [
        for (final report in filtered) ...[
          InkWell(
            onTap: () => openDetails(report),
            borderRadius: BorderRadius.circular(20),
            child: InfoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const IconTile(icon: Icons.assignment_outlined, size: 38),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'بلاغ ${displayReportNumber(report.id)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Icon(
                        Icons.chevron_left_rounded,
                        color: context.khota.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    report.description,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.khota.muted(0.76)),
                  ),

                  const SizedBox(height: 16),

                  ReportStatusSummary(
                    analysisStatus: report.analysisStatus,
                    reportStatus: report.reportStatus,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // Read only the signed-in citizen's reports.
  Widget buildLiveReports() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return InfoCard(
        child: Column(
          children: [
            const Text('سجّل الدخول لعرض بلاغاتك.'),

            const SizedBox(height: 12),

            if (kDebugMode) previewButton(),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InfoCard(
            child: Column(
              children: [
                const Text(
                  'تعذّر تحميل البلاغات. تحقق من الاتصال وصلاحيات Firestore.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                if (kDebugMode) previewButton(),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs
            .map(CitizenReport.fromFirestore)
            .toList();

        return buildReportList(reports);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        children: [
          const BrandIntro(
            eyebrow: 'بلاغاتي',
            title: 'كل خطوة موثّقة',
            description: 'تابع بلاغاتك، من إرسال الصورة إلى آخر تحديث.',
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 20),

          if (previewMode) ...[
            InfoCard(
              color: AppColors.tealLight.withValues(alpha: 0.18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'وضع المعاينة: هذه أمثلة تجريبية وليست بلاغات حقيقية.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        previewMode = false;
                        selectedFilter = 'الكل';
                      });
                    },
                    child: const Text('العودة إلى بلاغاتي الحقيقية'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            buildReportList(sampleReports),
          ] else
            buildLiveReports(),
        ],
      ),
    );
  }
}
