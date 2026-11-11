import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// [GpsReportLocationProvider] implements the device GPS and manual map picker.
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

/// Reads the device location and lets the reporter select a different point.
class GpsReportLocationProvider implements ReportLocationProvider {
  const GpsReportLocationProvider();

  static const _riyadh = LatLng(24.7136, 46.6753);

  @override
  Future<ReportLocation?> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('[Khota location] Device location service is disabled.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      debugPrint('[Khota location] Location permission: ${permission.name}.');
      return null;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) rethrow;

      debugPrint('[Khota location] Retrying with Android LocationManager.');
      position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          forceLocationManager: true,
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );
    }
    return ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: ReportLocation.sourceGps,
      accuracyMeters: position.accuracy,
    );
  }

  @override
  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  ) {
    return Navigator.of(context).push<ReportLocation>(
      MaterialPageRoute<ReportLocation>(
        builder: (_) => _ReportLocationPicker(
          center: initial == null
              ? _riyadh
              : LatLng(initial.latitude, initial.longitude),
          zoom: initial == null ? 12.0 : 17.0,
        ),
      ),
    );
  }

  @override
  Widget buildMap(BuildContext context, ReportLocation? location) {
    final point = location == null
        ? null
        : LatLng(location.latitude, location.longitude);
    return _ReportMap(
      key: ValueKey((location?.latitude, location?.longitude)),
      center: point ?? _riyadh,
      zoom: point == null ? 12.0 : 17.0,
      point: point,
    );
  }

  /// Turns the point into a readable place, e.g. "حي العليا، طريق الملك فهد",
  /// using OpenStreetMap's Nominatim service (the same map data as the app's
  /// map). One request per report, in Arabic. Returns null on any failure so
  /// the report can still be sent with its coordinates.
  @override
  Future<String?> addressFor(ReportLocation location) =>
      lookupAddress(location.latitude, location.longitude);

  static final Map<String, String?> _addressCache = {};

  static Future<String?> lookupAddress(double latitude, double longitude) async {
    if (kIsWeb) return null;
    final key =
        '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    if (_addressCache.containsKey(key)) return _addressCache[key];

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '17',
        'addressdetails': '1',
        'accept-language': 'ar',
      });
      final request = await client.getUrl(uri);
      // Nominatim requires an identifying User-Agent.
      request.headers.set(HttpHeaders.userAgentHeader, 'KhotaApp/1.0 (KSU)');
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      final address = data is Map ? data['address'] : null;
      final text = address is Map ? formatAddress(address) : null;
      _addressCache[key] = text;
      return text;
    } catch (error) {
      debugPrint('[Khota location] Address lookup failed: $error');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// "حي <district>، <street>" from Nominatim address parts; null if neither
  /// part is available.
  static String? formatAddress(Map<dynamic, dynamic> address) {
    String? part(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    var district = part(['neighbourhood', 'suburb', 'quarter', 'city_district']);
    if (district != null && !district.startsWith('حي')) {
      district = 'حي $district';
    }
    final street = part(['road', 'pedestrian', 'footway']);
    final parts = [if (district != null) district, if (street != null) street];
    if (parts.isEmpty) return part(['city', 'town', 'village']);
    return parts.join('، ');
  }
}

class _ReportLocationPicker extends StatefulWidget {
  const _ReportLocationPicker({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;

  @override
  State<_ReportLocationPicker> createState() => _ReportLocationPickerState();
}

class _ReportLocationPickerState extends State<_ReportLocationPicker> {
  ReportLocation? _selected;

  void _select(LatLng point) {
    setState(() {
      _selected = ReportLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        source: ReportLocation.sourceManual,
      );
    });
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(title: const Text('تحديد الموقع يدوياً')),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اضغط على مكان المشكلة في الخريطة، ثم أكّد الموقع.'),
            ),
            Expanded(
              child: _ReportMap(
                center: widget.center,
                zoom: widget.zoom,
                point: selected == null
                    ? null
                    : LatLng(selected.latitude, selected.longitude),
                onSelect: _select,
              ),
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  selected.coordinatesText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: selected == null ? null : _confirm,
                child: const Text('تأكيد الموقع'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMap extends StatelessWidget {
  const _ReportMap({
    super.key,
    required this.center,
    required this.zoom,
    required this.point,
    this.onSelect,
  });

  final LatLng center;
  final double zoom;
  final LatLng? point;
  final ValueChanged<LatLng>? onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = point;
    final select = onSelect;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            maxZoom: 19,
            // Disabling double-tap zoom lets each tap select immediately.
            interactionOptions: select == null
                ? const InteractionOptions(flags: InteractiveFlag.none)
                : const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                  ),
            onTap: select == null ? null : (_, coordinate) => select(coordinate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'sa.edu.ksu.khota_app',
              maxNativeZoom: 19,
            ),
            if (selected != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: selected,
                    width: 24,
                    height: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          bottom: 2,
          right: 4,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: colors.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 26),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              await launchUrl(Uri.https('www.openstreetmap.org', '/copyright'));
            },
            child: const Text(
              '© OpenStreetMap contributors',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
