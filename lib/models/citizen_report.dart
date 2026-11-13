import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_format.dart';
import '../utils/report_sort.dart';
import '../widgets/report_status_widgets.dart';

/// One of the citizen's own reports, as shown in "بلاغاتي" and its details.
class CitizenReport {
  const CitizenReport({
    required this.id,
    required this.description,
    required this.reportStatus,
    required this.analysisStatus,
    this.imageUrl,
    this.createdAt,
    this.address,
    this.latitude,
    this.longitude,
    this.issueClass,
    this.severity,
  });

  final String id;
  final String description;

  /// Display label, e.g. [ReportStatusLabels.pending].
  final String reportStatus;

  /// Display label, e.g. [ReportStatusLabels.analyzing].
  final String analysisStatus;

  // New reports store a private Firebase Storage path.
  final String? imageUrl;

  final DateTime? createdAt;

  /// Saved place name; older reports have only the point.
  final String? address;
  final double? latitude;
  final double? longitude;

  /// Analysis results; null until the computer vision result is stored.
  final String? issueClass;
  final String? severity;

  static const noDate = 'التاريخ غير متاح';

  /// "10 نوفمبر 2026", the same format as the home cards.
  String get dateText =>
      createdAt == null ? noDate : formatArabicDate(createdAt!);

  /// Same order as the home "آخر البلاغات" list: newest first.
  static int newestFirst(CitizenReport first, CitizenReport second) =>
      compareNewestFirst(
        first.createdAt,
        first.id,
        second.createdAt,
        second.id,
      );

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
  ) => CitizenReport.fromMap(doc.id, doc.data());

  factory CitizenReport.fromMap(String id, Map<String, dynamic> data) {
    final description = (data['description'] ?? '').toString().trim();
    final image = data['imageUrl'];
    final created = data['createdAt'];
    final location = data['location'];
    final address = data['address'];
    final issueClass = data['issueClass'];
    final severity = data['severity'];

    return CitizenReport(
      id: id,
      description: description.isEmpty
          ? 'بلاغ عن مشكلة في الرصيف'
          : description,
      reportStatus: reportLabel(data['reportStatus'] ?? data['status']),
      analysisStatus: analysisLabel(
        data['analysisStatus'] ?? data['imageAnalysisStatus'],
      ),
      imageUrl: image is String && image.isNotEmpty ? image : null,
      createdAt: created is Timestamp ? created.toDate() : null,
      address: address is String && address.trim().isNotEmpty
          ? address.trim()
          : null,
      latitude: location is GeoPoint ? location.latitude : null,
      longitude: location is GeoPoint ? location.longitude : null,
      issueClass: issueClass is String ? issueClass : null,
      severity: severity is String ? severity : null,
    );
  }
}
