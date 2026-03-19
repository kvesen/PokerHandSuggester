/// Camera lifecycle management and photo capture service.
library;

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Possible states / error conditions returned by [CameraService].
enum CameraStatus {
  /// Camera is ready to use.
  ready,

  /// The user denied the camera permission.
  permissionDenied,

  /// The user permanently denied the camera permission (must open settings).
  permissionPermanentlyDenied,

  /// No cameras are available on the device.
  noCameraAvailable,

  /// An unexpected error occurred — see [CameraService.lastError].
  error,
}

/// Manages the device camera: permissions, lifecycle, and photo capture.
///
/// Usage:
/// ```dart
/// final service = CameraService();
/// await service.initialize();
/// if (service.status == CameraStatus.ready) {
///   final path = await service.capturePhoto();
/// }
/// service.dispose();
/// ```
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _activeCameraIndex = 0;
  CameraStatus _status = CameraStatus.error;
  String? _lastError;

  /// The current status of the camera.
  CameraStatus get status => _status;

  /// Human-readable description of the last error (if any).
  String? get lastError => _lastError;

  /// The active [CameraController]. Non-null only when [status] is [CameraStatus.ready].
  CameraController? get controller => _controller;

  // --------------------------------------------------------------------------
  // Initialize
  // --------------------------------------------------------------------------

  /// Requests camera permission and initializes the back camera.
  Future<void> initialize() async {
    final permStatus = await Permission.camera.request();
    if (permStatus.isPermanentlyDenied) {
      _status = CameraStatus.permissionPermanentlyDenied;
      _lastError = 'Camera permission permanently denied. '
          'Please enable it in Settings.';
      return;
    }
    if (!permStatus.isGranted) {
      _status = CameraStatus.permissionDenied;
      _lastError = 'Camera permission is required to scan cards.';
      return;
    }

    try {
      _cameras = await availableCameras();
    } catch (e) {
      _status = CameraStatus.error;
      _lastError = 'Failed to query cameras: $e';
      return;
    }

    if (_cameras.isEmpty) {
      _status = CameraStatus.noCameraAvailable;
      _lastError = 'No cameras found on this device.';
      return;
    }

    // Default to the back camera if available.
    _activeCameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (_activeCameraIndex < 0) _activeCameraIndex = 0;

    await _initController(_cameras[_activeCameraIndex]);
  }

  // --------------------------------------------------------------------------
  // Switch camera
  // --------------------------------------------------------------------------

  /// Switches to the other camera (front ↔ back).
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    _activeCameraIndex = (_activeCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_activeCameraIndex]);
  }

  // --------------------------------------------------------------------------
  // Capture
  // --------------------------------------------------------------------------

  /// Takes a photo and returns its file path, or `null` on failure.
  Future<String?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
      final xFile = await _controller!.takePicture();
      return xFile.path;
    } catch (e) {
      _lastError = 'Failed to capture photo: $e';
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Dispose
  // --------------------------------------------------------------------------

  /// Releases all camera resources.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<void> _initController(CameraDescription camera) async {
    await _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _controller!.initialize();
      _status = CameraStatus.ready;
      _lastError = null;
    } catch (e) {
      _status = CameraStatus.error;
      _lastError = 'Failed to initialize camera: $e';
    }
  }
}
