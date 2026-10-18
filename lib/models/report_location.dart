/// Where a report was taken. Filled by the location step (GPS or manual map
/// selection) before the report is submitted.
class ReportLocation {
  const ReportLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.accuracyMeters,
  });

  /// Coordinates came from the device GPS.
  static const sourceGps = 'gps';

  /// The citizen picked the point on the map (location permission denied).
  static const sourceManual = 'manual';

  /// TEMPORARY placeholder used until the location step is connected.
  /// Remove together with TemporaryReportLocationProvider once GPS is in place.
  static const sourceTemporary = 'temporary';

  final double latitude;
  final double longitude;
  final String source;

  /// GPS accuracy radius in metres (smaller is better). Null when the point
  /// was chosen manually or is temporary.
  final double? accuracyMeters;

  bool get isValid =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  /// "24.71360، 46.67530" — shown when no street address is available.
  String get coordinatesText =>
      '${latitude.toStringAsFixed(5)}، ${longitude.toStringAsFixed(5)}';
}
