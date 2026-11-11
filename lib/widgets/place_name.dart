import 'package:flutter/material.dart';

import '../services/report_location_service.dart';

/// Shows a report's place as a name ("حي العليا، طريق الملك فهد"), never as
/// raw coordinates. Uses the saved [address] when there is one; for older
/// reports saved without it, looks the name up once (results are cached).
class PlaceName extends StatefulWidget {
  const PlaceName({
    super.key,
    this.address,
    this.latitude,
    this.longitude,
    this.style,
    this.maxLines = 1,
  });

  final String? address;
  final double? latitude;
  final double? longitude;
  final TextStyle? style;
  final int maxLines;

  static const fallback = 'الموقع المحدد على الخريطة';

  @override
  State<PlaceName> createState() => _PlaceNameState();
}

class _PlaceNameState extends State<PlaceName> {
  Future<String?>? _lookup;

  bool get _hasAddress => (widget.address ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasAddress && widget.latitude != null && widget.longitude != null) {
      _lookup = GpsReportLocationProvider.lookupAddress(
        widget.latitude!,
        widget.longitude!,
      );
    }
  }

  Text _text(String value) => Text(
    value,
    maxLines: widget.maxLines,
    overflow: TextOverflow.ellipsis,
    style: widget.style,
  );

  @override
  Widget build(BuildContext context) {
    if (_hasAddress) return _text(widget.address!.trim());
    if (_lookup == null) return _text(PlaceName.fallback);
    return FutureBuilder<String?>(
      future: _lookup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _text('جارٍ تحديد اسم الموقع…');
        }
        return _text(snapshot.data ?? PlaceName.fallback);
      },
    );
  }
}
