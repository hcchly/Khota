
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../widgets/info_card.dart';
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

    if (s == 'resolved' ||
        s == 'completed' ||
        s == 'done' ||
        s == 'تم الحل') {
      return ReportStatusLabels.resolved;
    }

    return 'حالة البلاغ غير متاحة';
  }

  static String analysisLabel(dynamic value) {
    final s = (value ?? '').toString().trim().toLowerCase();

    if (s == 'processing' ||
        s == 'analyzing' ||
        s == 'جارٍ تحليل الصورة') {
      return ReportStatusLabels.analyzing;
    }

    if (s == 'completed' || s == 'done') {
      return 'اكتمل تحليل الصورة';
    }

    if (s == 'failed') {
      return 'تعذّر تحليل الصورة';
    }

    return 'حالة التحليل غير متاحة';
  }

  factory CitizenReport.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final description =
        (data['description'] ?? '').toString().trim();
    final image = data['imageUrl'];

    return CitizenReport(
      id: doc.id,
      description: description.isEmpty
          ? 'بلاغ عن مشكلة في الرصيف'
          : description,
      reportStatus: reportLabel(
        data['reportStatus'] ?? data['status'],
      ),
      analysisStatus: analysisLabel(
        data['analysisStatus'] ??
            data['imageAnalysisStatus'],
      ),
      imageUrl: image is String && image.isNotEmpty
          ? image
          : null,
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    this.initialPreview = false,
  });

  final bool initialPreview;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedFilter = 'الكل';
  late bool previewMode = widget.initialPreview;

  // UI preview only. These are NOT actual citizen reports.
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل البلاغ',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
                const SizedBox(height: 12),
                Text('رقم البلاغ: ${report.id}'),
                const SizedBox(height: 12),
                Text(report.description),
                if (report.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  Image.network(
                    report.imageUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Text(
                        'تعذّر عرض صورة البلاغ',
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                ReportStatusSummary(
                  analysisStatus: report.analysisStatus,
                  reportStatus: report.reportStatus,
                ),
                if (previewMode) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'هذا بلاغ تجريبي وليس بلاغًا حقيقيًا.',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

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

  Widget buildReportList(List<CitizenReport> reports) {
    final filtered = selectedFilter == 'الكل'
        ? reports
        : reports
            .where(
              (r) => r.reportStatus == selectedFilter,
            )
            .toList();

    if (filtered.isEmpty) {
      return InfoCard(
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.teal,
            ),
            const SizedBox(height: 12),
            Text(
              reports.isEmpty
                  ? 'لا توجد بلاغات بعد'
                  : 'لا توجد بلاغات بهذه الحالة',
            ),
            if (reports.isEmpty && !previewMode) ...[
              const SizedBox(height: 12),
              previewButton(),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final report in filtered) ...[
          InkWell(
            onTap: () => openDetails(report),
            borderRadius: BorderRadius.circular(20),
            child: InfoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بلاغ #${report.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(report.description),
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

  Widget buildLiveReports() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return InfoCard(
        child: Column(
          children: [
            const Text('سجّل الدخول لعرض بلاغاتك.'),
            const SizedBox(height: 12),
            previewButton(),
          ],
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
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
                previewButton(),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(16, 24, 16, 96),
        children: [
          Text(
            'بلاغاتي',
            style: text.headlineSmall?.copyWith(
              color: AppColors.indigo,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تابع حالة تحليل الصورة وحالة البلاغ بشكل منفصل.',
          ),
          const SizedBox(height: 20),
          const Text(
            'تصفية حسب حالة البلاغ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // These filters change the visible reports.
          ReportStatusFilters(
            selectedFilter: selectedFilter,
            onFilterChanged: (value) {
              setState(() => selectedFilter = value);
            },
          ),

          const SizedBox(height: 20),

          if (previewMode) ...[
            InfoCard(
              color: AppColors.tealLight.withValues(
                alpha: 0.18,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'وضع المعاينة: هذه أمثلة تجريبية وليست بلاغات حقيقية.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        previewMode = false;
                        selectedFilter = 'الكل';
                      });
                    },
                    child: const Text(
                      'العودة إلى بلاغاتي الحقيقية',
                    ),
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
