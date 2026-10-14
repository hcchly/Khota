import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

abstract class ReportCameraService {
  Future<Uint8List?> capture();
  Future<Uint8List?> recover();
}

class ImagePickerReportCamera implements ReportCameraService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> capture() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return file == null ? null : await file.readAsBytes();
  }

  @override
  Future<Uint8List?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    final files = response.files;
    return files == null || files.isEmpty ? null : await files.first.readAsBytes();
  }
}
