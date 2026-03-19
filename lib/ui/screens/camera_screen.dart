/// Camera screen — live preview, capture, and gallery pick.
library;

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../recognition/card_detector.dart';
import '../../recognition/image_processor.dart';
import '../../services/camera_service.dart';
import 'detection_review_screen.dart';
import 'manual_input_screen.dart';

/// Full-screen camera UI.
///
/// Flow:
/// 1. Shows a live camera preview.
/// 2. User captures a photo (shutter button) or picks from gallery.
/// 3. Runs card detection on the captured image.
/// 4. Navigates to [DetectionReviewScreen] with the result.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _cameraService = CameraService();
  final _imagePicker = ImagePicker();
  final _detector = CardDetector();

  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _detector.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Camera initialization
  // ---------------------------------------------------------------------------

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    if (mounted) setState(() => _isInitializing = false);
  }

  // ---------------------------------------------------------------------------
  // Capture / gallery
  // ---------------------------------------------------------------------------

  Future<void> _capturePhoto() async {
    final path = await _cameraService.capturePhoto();
    if (path != null) await _processImage(path);
  }

  Future<void> _pickFromGallery() async {
    final xFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (xFile != null) await _processImage(xFile.path);
  }

  Future<void> _processImage(String rawPath) async {
    setState(() {
      _isProcessing = true;
      _capturedImagePath = rawPath;
    });

    try {
      final processedPath = await ImageProcessor.prepareForOcr(rawPath);
      final result = await _detector.detectCards(processedPath);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DetectionReviewScreen(
            imagePath: rawPath,
            detectionResult: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detection failed: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Manual Input',
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const ManualInputScreen(),
              ),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _capturedImagePath = null;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Table'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_cameraService.status == CameraStatus.ready)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              tooltip: 'Switch camera',
              onPressed: () async {
                await _cameraService.switchCamera();
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Initializing camera…',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_capturedImagePath != null)
              Expanded(
                child: Image.file(
                  File(_capturedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text('Detecting cards…',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }

    if (_cameraService.status != CameraStatus.ready) {
      return _buildErrorView();
    }

    return Column(
      children: [
        // Live preview
        Expanded(
          child: ClipRect(
            child: CameraPreview(_cameraService.controller!),
          ),
        ),

        // Bottom controls
        Container(
          color: Colors.black,
          padding:
              const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              _CircleIconButton(
                icon: Icons.photo_library,
                size: 52,
                onTap: _pickFromGallery,
                tooltip: 'Pick from Gallery',
              ),

              // Shutter button
              GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Manual input shortcut
              _CircleIconButton(
                icon: Icons.edit_note,
                size: 52,
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManualInputScreen(),
                  ),
                ),
                tooltip: 'Manual Input',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    final isPermanent =
        _cameraService.status == CameraStatus.permissionPermanentlyDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              _cameraService.lastError ?? 'Camera unavailable.',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isPermanent)
              FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                onPressed: openAppSettings,
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: const Text('Pick from Gallery',
                  style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white)),
              onPressed: _pickFromGallery,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text('Manual Input',
                  style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white)),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const ManualInputScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
            border: Border.all(color: Colors.white54),
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.46),
        ),
      ),
    );
  }
}
