import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:khota_app/models/report_location.dart';
import 'package:khota_app/services/report_camera_service.dart';
import 'package:khota_app/services/report_location_service.dart';

/// 1x1 PNG.
final testPhoto = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9l8AAAAASUVORK5CYII=',
);

class FakeCamera implements ReportCameraService {
  Uint8List? next = testPhoto;
  bool fail = false;
  int galleryCalls = 0;

  @override
  Future<Uint8List?> capture() async {
    if (fail) throw Exception('permission denied');
    return next;
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    galleryCalls++;
    if (fail) throw Exception('permission denied');
    return next;
  }

  @override
  Future<Uint8List?> recover() async => null;
}

class FakeLocationProvider implements ReportLocationProvider {
  FakeLocationProvider({this.location = gpsGood, this.address});

  static const gpsGood = ReportLocation(
    latitude: 24.7136,
    longitude: 46.6753,
    source: ReportLocation.sourceGps,
    accuracyMeters: 12,
  );

  ReportLocation? location;
  String? address;

  @override
  Future<ReportLocation?> currentLocation() async => location;

  @override
  Future<ReportLocation?> pickManually(
    BuildContext context,
    ReportLocation? initial,
  ) async => null;

  @override
  Widget? buildMap(BuildContext context, ReportLocation? location) => null;

  @override
  Future<String?> addressFor(ReportLocation location) async => address;
}
