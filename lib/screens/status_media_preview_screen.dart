import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../provider/status_provider.dart';

class StatusMediaPreviewScreen extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;
  final String? fileName;
  final String mediaType; // 'image' | 'video'

  const StatusMediaPreviewScreen({
    super.key,
    this.file,
    this.bytes,
    this.fileName,
    required this.mediaType,
  });

  @override
  State<StatusMediaPreviewScreen> createState() => _StatusMediaPreviewScreenState();
}

class _StatusMediaPreviewScreenState extends State<StatusMediaPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video' && widget.file != null && !kIsWeb) {
      _videoController = VideoPlayerController.file(widget.file!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isVideoInitialized = true);
            _videoController?.setLooping(true);
            _videoController?.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _publishStatus() async {
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    final caption = _captionController.text.trim();

    final success = await statusProvider.publishMediaStatus(
      file: widget.file,
      bytes: widget.bytes,
      fileName: widget.fileName,
      mediaType: widget.mediaType,
      caption: caption.isNotEmpty ? caption : null,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(statusProvider.errorMessage ?? 'Failed to upload status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusProvider = Provider.of<StatusProvider>(context);

    Widget mediaWidget;
    if (widget.mediaType == 'video') {
      mediaWidget = _isVideoInitialized && _videoController != null
          ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          : const Center(
              child: CircularProgressIndicator(color: Color(0xFF0078FF)),
            );
    } else {
      if (widget.bytes != null) {
        mediaWidget = Image.memory(
          widget.bytes!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (widget.file != null && !kIsWeb) {
        mediaWidget = Image.file(
          widget.file!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        mediaWidget = const Center(
          child: Icon(Icons.image, color: Colors.white54, size: 64),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Media Preview
            Center(
              child: mediaWidget,
            ),

            // Top Bar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: statusProvider.isUploading ? null : () => Navigator.pop(context),
                    ),
                  ),
                  if (widget.mediaType == 'video')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Video Status', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Caption Bar & Send Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusProvider.isUploading) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: statusProvider.uploadProgress > 0 ? statusProvider.uploadProgress : null,
                              color: const Color(0xFF0078FF),
                              backgroundColor: Colors.white24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Uploading status... ${(statusProvider.uploadProgress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2C34),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _captionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: const Color(0xFF0078FF),
                          foregroundColor: Colors.white,
                          onPressed: statusProvider.isUploading ? null : _publishStatus,
                          child: statusProvider.isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
