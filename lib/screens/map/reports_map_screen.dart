import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/khota_colors.dart';
import '../../utils/report_labels.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/brand_surface.dart';
import '../../widgets/report_map_marker.dart';
import '../../widgets/report_status_widgets.dart';

class ReportsMapScreen extends StatefulWidget {
  const ReportsMapScreen({super.key});

  @override
  State<ReportsMapScreen> createState() => _ReportsMapScreenState();
}

class _ReportsMapScreenState extends State<ReportsMapScreen> {
  final _controller = MapController();
  Timer? _viewportTimer;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _markers;

  @override
  void dispose() {
    _viewportTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadMarkers(LatLngBounds bounds) {
    final query = FirebaseFirestore.instance
        .collection('mapReports')
        .where('latitude', isGreaterThanOrEqualTo: bounds.south)
        .where('latitude', isLessThanOrEqualTo: bounds.north)
        .where('longitude', isGreaterThanOrEqualTo: bounds.west)
        .where('longitude', isLessThanOrEqualTo: bounds.east)
        .orderBy('latitude')
        .orderBy('longitude');

    setState(() => _markers = query.snapshots());
  }

  void _queueLoad(MapCamera camera, bool _) {
    _viewportTimer?.cancel();
    _viewportTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadMarkers(camera.visibleBounds);
    });
  }

  void _showReport(Map<String, dynamic> data) {
    final issueClass = issueClassLabel(data['issueClass']);
    final severity = severityLabel(data['severity']);
    final status = switch (data['reportStatus']) {
      'pending' => ReportStatusLabels.pending,
      'in_progress' => ReportStatusLabels.inProgress,
      'resolved' => ReportStatusLabels.resolved,
      _ => 'غير متاحة',
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const BrandIntro(
              title: 'كل بلاغ له أثر',
              description: 'ملخص المشكلة المسجلة في هذا الموقع.',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('نوع المشكلة'),
              subtitle: Text(issueClass),
            ),
            ListTile(title: const Text('الشدة'), subtitle: Text(severity)),
            ListTile(title: const Text('حالة البلاغ'), subtitle: Text(status)),
          ],
        ),
      ),
    );
  }

  Marker? _marker(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return Marker(
      key: ValueKey(doc.id),
      point: LatLng(latitude.toDouble(), longitude.toDouble()),
      width: 48,
      height: 48,
      // Coloured by report status; warning icon and red border when severe.
      child: ReportMapMarker(
        reportStatus: data['reportStatus'],
        severity: data['severity'],
        onPressed: () => _showReport(data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'خريطة خُطى'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _markers,
        builder: (context, snapshot) {
          final loading =
              !snapshot.hasError &&
              (_markers == null ||
                  snapshot.connectionState == ConnectionState.waiting);
          final markers = loading || snapshot.hasError
              ? const <Marker>[]
              : (snapshot.data?.docs ?? [])
                    .map(_marker)
                    .whereType<Marker>()
                    .toList();

          return Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: const LatLng(24.7136, 46.6753),
                  initialZoom: 11,
                  minZoom: 8,
                  maxZoom: 19,
                  onMapReady: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _loadMarkers(_controller.camera.visibleBounds);
                      }
                    });
                  },
                  onPositionChanged: _queueLoad,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'sa.edu.ksu.khota_app',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              if (loading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                )
              else if (snapshot.hasError || markers.isEmpty)
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  end: 12,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: snapshot.hasError
                            ? TextButton(
                                onPressed: () => _loadMarkers(
                                  _controller.camera.visibleBounds,
                                ),
                                child: const Text(
                                  'تعذّر تحميل البلاغات. إعادة المحاولة',
                                ),
                              )
                            : const Text(
                                'لا توجد بلاغات في الجزء الظاهر من الخريطة',
                              ),
                      ),
                    ),
                  ),
                ),
              const Positioned(
                bottom: 8,
                left: 8,
                child: ReportMapLegend(),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: context.khota.surface,
                    minimumSize: const Size(0, 26),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    await launchUrl(
                      Uri.https('www.openstreetmap.org', '/copyright'),
                    );
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
        },
      ),
    );
  }
}
