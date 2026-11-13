
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

abstract class ReportCameraService {
  Future<Uint8List?> capture();
  Future<Uint8List?> pickFromGallery();
  Future<Uint8List?> recover();
}

class ImagePickerReportCamera implements ReportCameraService {
  final ImagePicker _picker = ImagePicker();

  // Compress images before upload.
  static const _maxSide = 1600.0;
  static const _quality = 80;

  // Supported image extensions.
  static const _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  bool _isSupportedImage(String fileName) {
    final name = fileName.toLowerCase();

    if (!name.contains('.')) return false;

    final extension = name.split('.').last;
    return _allowedExtensions.contains(extension);
  }

  Future<Uint8List?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
      requestFullMetadata: false,
    );

    if (file == null) return null;

    // Validate gallery image format.
    if (source == ImageSource.gallery &&
        !_isSupportedImage(file.name)) {
      throw const FormatException(
        'صيغة الصورة غير مدعومة. اختاري JPG أو PNG أو WebP.',
      );
    }

    return await file.readAsBytes();
  }

  @override
  Future<Uint8List?> capture() =>
      _pick(ImageSource.camera);

  @override
  Future<Uint8List?> pickFromGallery() =>
      _pick(ImageSource.gallery);

  @override
  Future<Uint8List?> recover() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final response = await _picker.retrieveLostData();

    if (response.exception != null) {
      throw response.exception!;
    }

    final files = response.files;

    return files == null || files.isEmpty
        ? null
        : await files.first.readAsBytes();
  }
}
