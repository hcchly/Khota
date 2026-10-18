import 'report_location.dart';

/// Returned by the new-report screen after the report has been saved.
class SubmittedReport {
  const SubmittedReport({
    required this.id,
    required this.location,
    this.address,
  });

  final String id;
  final ReportLocation location;

  /// Street address when the location step provides one.
  final String? address;
}
