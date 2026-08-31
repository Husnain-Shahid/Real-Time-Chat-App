import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CropImageScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final File? imageFile;

  const CropImageScreen({
    super.key,
    this.imageBytes,
    this.imageFile,
  });

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final GlobalKey _cropAreaKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  int _quarterTurns = 0;
  bool _isProcessing = false;
  Uint8List? _loadedBytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    if (widget.imageBytes != null) {
      setState(() => _loadedBytes = widget.imageBytes);
    } else if (widget.imageFile != null) {
      if (!kIsWeb) {
        final bytes = await widget.imageFile!.readAsBytes();
        if (mounted) setState(() => _loadedBytes = bytes);
      }
    }
  }

  void _rotateImage() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _resetTransform() {
    setState(() {
      _quarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave() async {
    setState(() => _isProcessing = true);
    try {
      final boundary = _cropAreaKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context, _loadedBytes);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.pop(context, _loadedBytes);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (mounted) {
        Navigator.pop(context, pngBytes);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        Navigator.pop(context, _loadedBytes);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cropBoxSize = (screenSize.width * 0.85).clamp(240.0, 420.0);

    if (_loadedBytes == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0078FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Crop profile photo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            tooltip: 'Rotate',
            onPressed: _rotateImage,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset',
            onPressed: _resetTransform,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Center Crop Viewport
          Center(
            child: SizedBox(
              width: cropBoxSize,
              height: cropBoxSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cropBoxSize / 2),
                child: RepaintBoundary(
                  key: _cropAreaKey,
                  child: Container(
                    color: Colors.black,
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.5,
                      maxScale: 4.0,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: RotatedBox(
                        quarterTurns: _quarterTurns,
                        child: Image.memory(
                          _loadedBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Circular Grid Overlay Guide
          IgnorePointer(
            child: Center(
              child: Container(
                width: cropBoxSize,
                height: cropBoxSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0078FF), width: 2),
                ),
              ),
            ),
          ),

          // Bottom Controls Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, color: Colors.white, size: 20),
                    label: Text(
                      _isProcessing ? 'Cropping...' : 'Done',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: _isProcessing ? null : _cropAndSave,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
