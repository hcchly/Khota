import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// State of the in-app camera.
enum LiveCameraStatus { idle, starting, ready, denied, unavailable }

/// Owns the device camera for the new-report screen: start, stop, flash and
/// taking a photo. When the camera cannot be used (simulator, no permission)
/// the screen falls back to the system camera and the gallery.
class LiveCameraController extends ChangeNotifier {
  CameraController? _camera;
  LiveCameraStatus _status = LiveCameraStatus.idle;
  bool _flashOn = false;
  bool _disposed = false;

  LiveCameraStatus get status => _status;
  bool get isReady => _status == LiveCameraStatus.ready && _camera != null;
  bool get flashOn => _flashOn;
  CameraController? get camera => _camera;

  void _set(LiveCameraStatus status) {
    _status = status;
    if (!_disposed) notifyListeners();
  }

  /// Opens the back camera. Safe to call more than once.
  Future<void> start() async {
    if (_status == LiveCameraStatus.starting || isReady) return;
    if (_status == LiveCameraStatus.denied ||
        _status == LiveCameraStatus.unavailable) {
      return;
    }
    _set(LiveCameraStatus.starting);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _set(LiveCameraStatus.unavailable);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // 1080p keeps defects visible and uploads quickly (NFR: 10 seconds).
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      _camera = controller;
      _set(LiveCameraStatus.ready);
    } on CameraException catch (error) {
      _camera = null;
      _set(
        error.code.startsWith('CameraAccess')
            ? LiveCameraStatus.denied
            : LiveCameraStatus.unavailable,
      );
    } catch (_) {
      // Simulator or a platform without the camera plugin.
      _camera = null;
      _set(LiveCameraStatus.unavailable);
    }
  }

  /// Releases the camera (another step is shown or the app is in background).
  Future<void> stop() async {
    final controller = _camera;
    _camera = null;
    if (_status == LiveCameraStatus.ready ||
        _status == LiveCameraStatus.starting) {
      _set(LiveCameraStatus.idle);
    }
    await controller?.dispose();
  }

  Future<void> toggleFlash() async {
    final controller = _camera;
    if (controller == null) return;
    _flashOn = !_flashOn;
    try {
      await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      _flashOn = false;
    }
    if (!_disposed) notifyListeners();
  }

  /// Takes a photo and returns its JPEG bytes.
  Future<Uint8List?> takePicture() async {
    final controller = _camera;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }
    final file = await controller.takePicture();
    return file.readAsBytes();
  }

  @override
  void dispose() {
    _disposed = true;
    _camera?.dispose();
    _camera = null;
    super.dispose();
  }
}

/// Live camera image that fills its box (cropped like a camera app).
class LiveCameraPreview extends StatelessWidget {
  const LiveCameraPreview({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.shrink();
    // previewSize is reported in landscape; swap it for a portrait phone.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
