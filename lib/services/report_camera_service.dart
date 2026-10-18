import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

abstract class ReportCameraService {
  Future<Uint8List?> capture();
  Future<Uint8List?> pickFromGallery();
  Future<Uint8List?> recover();
}

class ImagePickerReportCamera implements ReportCameraService {
  final ImagePicker _picker = ImagePicker();

  // Smaller images upload faster (NFR: confirmation within 10 seconds).
  // 1600 px with 80% quality is usually 300–700 KB and keeps defects visible.
  static const _maxSide = 1600.0;
  static const _quality = 80;

  Future<Uint8List?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
      requestFullMetadata: false,
    );
    return file == null ? null : await file.readAsBytes();
  }

  @override
  Future<Uint8List?> capture() => _pick(ImageSource.camera);

  @override
  Future<Uint8List?> pickFromGallery() => _pick(ImageSource.gallery);

  @override
  Future<Uint8List?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    final files = response.files;
    return files == null || files.isEmpty ? null : await files.first.readAsBytes();
  }
}
