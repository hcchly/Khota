import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class PrivateReportImage extends StatefulWidget {
  const PrivateReportImage({
    super.key,
    required this.imageRef,
    this.height = 160,
    this.fit = BoxFit.cover,
  });

  final String imageRef;
  final double height;
  final BoxFit fit;

  @override
  State<PrivateReportImage> createState() =>
      _PrivateReportImageState();
}

class _PrivateReportImageState
    extends State<PrivateReportImage> {

  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(
    covariant PrivateReportImage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageRef != widget.imageRef) {
      _load();
    }
  }

  void _load() {
    _bytes = StorageService()
        .downloadImage(widget.imageRef);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {

        if (snapshot.connectionState !=
            ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return SizedBox(
            height: widget.height,
            child: const Center(
              child: Text(
                'تعذّر عرض صورة البلاغ',
              ),
            ),
          );
        }

        return Image.memory(
          snapshot.data!,
          height: widget.height,
          fit: widget.fit,
          semanticLabel: 'صورة البلاغ',
          errorBuilder: (_, _, _) =>
              const Text(
                'تعذّر عرض صورة البلاغ',
              ),
        );
      },
    );
  }
}
