import 'package:flutter/widgets.dart';

import '../models/report_location.dart';

/// Connection point between the new-report flow and the location task.
///
/// The new-report screen (step 2, "تأكيد الموقع") calls:
///  * [currentLocation] when the step opens, to get the GPS position with its
///    accuracy (`accuracyMeters`).
///  * [pickManually] when the citizen taps "تحديد الموقع يدوياً", or when the
///    location permission is denied, to choose the point on a map.
///  * [buildMap] to draw the map in the step.
///
/// The location task replaces [TemporaryReportLocationProvider] with a real
/// implementation (GPS + flutter_map) and passes it to NewReportScreen.
abstract class ReportLocationProvider {
  /// Current device position, or null if it is unavailable or denied.
  Future<ReportLocation?> currentLocation();

  /// Lets the citizen choose the point on a map. Returns null if cancelled.
  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  );

  /// The map shown in step 2, centred on [location]. Return null to show the
  /// built-in placeholder.
  Widget? buildMap(BuildContext context, ReportLocation? location);

  /// Human-readable address (district, street), or null if not available.
  Future<String?> addressFor(ReportLocation location);
}

/// TEMPORARY: a fixed point in Riyadh so report submission can be built and
/// tested before GPS and the map are connected. Reports saved with it are
/// marked `locationSource: 'temporary'` so they can be found and deleted.
class TemporaryReportLocationProvider implements ReportLocationProvider {
  const TemporaryReportLocationProvider();

  @override
  Future<ReportLocation?> currentLocation() async {
    return const ReportLocation(
      latitude: 24.7136,
      longitude: 46.6753,
      source: ReportLocation.sourceTemporary,
    );
  }

  @override
  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  ) async => null;

  @override
  Widget? buildMap(BuildContext context, ReportLocation? location) => null;

  @override
  Future<String?> addressFor(ReportLocation location) async => null;
}
