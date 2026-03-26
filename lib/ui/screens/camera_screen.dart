/// Camera screen — live preview, capture, and gallery pick.
library;

import 'dart:io';
import 'dart:ui';

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
    await Future.wait([
      _cameraService.initialize(),
      _detector.loadModel(),
    ]);
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
          content: Text('Detection failed: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Scan Table',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.black.withOpacity(0.4),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_cameraService.status == CameraStatus.ready)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Initializing camera…',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_isProcessing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (_capturedImagePath != null)
            Image.file(
              File(_capturedImagePath!),
              fit: BoxFit.cover,
            ),
          // Blur overlay during processing
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black54),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Analyzing Cards…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          padding: EdgeInsets.fromLTRB(32, 24, 32, MediaQuery.of(context).padding.bottom + 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              _CircleIconButton(
                icon: Icons.photo_library_rounded,
                size: 56,
                onTap: _pickFromGallery,
                tooltip: 'Pick from Gallery',
              ),

              // Shutter button (Modernized)
              Semantics(
                label: 'Capture photo',
                button: true,
                child: GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Manual input shortcut
              _CircleIconButton(
                icon: Icons.edit_note_rounded,
                size: 56,
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
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Colors.black],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            _cameraService.lastError ?? 'Camera unavailable',
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'We need camera access to scan your table and calculate odds automatically.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          if (isPermanent) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.settings_rounded, size: 20),
                label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: openAppSettings,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
              label: const Text('Pick from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _pickFromGallery,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
              label: const Text('Manual Input', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const ManualInputScreen(),
                ),
              ),
            ),
          ),
        ],
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
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(icon, color: Colors.white, size: size * 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
