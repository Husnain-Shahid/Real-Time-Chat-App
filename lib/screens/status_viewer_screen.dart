import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/status_model.dart';
import '../provider/status_provider.dart';

class StatusViewerScreen extends StatefulWidget {
  final List<StatusModel> statuses;
  final int initialUserIndex;

  const StatusViewerScreen({
    super.key,
    required this.statuses,
    this.initialUserIndex = 0,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentUserIndex;
  int _currentStoryIndex = 0;

  late AnimationController _animController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex.clamp(0, widget.statuses.length - 1);
    _animController = AnimationController(vsync: this);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadStory(storyIndex: 0);
  }

  @override
  void dispose() {
    _animController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  StatusModel get _currentStatus => widget.statuses[_currentUserIndex];
  List<StatusItemModel> get _currentItems => _currentStatus.activeItems;
  StatusItemModel? get _currentItem {
    if (_currentStoryIndex < _currentItems.length) {
      return _currentItems[_currentStoryIndex];
    }
    return null;
  }

  bool get _isMyStatus {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return _currentStatus.uid == currentUserId;
  }

  void _loadStory({required int storyIndex}) {
    _animController.stop();
    _animController.reset();
    _videoController?.dispose();
    _videoController = null;

    if (storyIndex >= _currentItems.length) {
      _nextUser();
      return;
    }

    setState(() {
      _currentStoryIndex = storyIndex;
    });

    final item = _currentItem;
    if (item == null) return;

    // Mark as viewed in Firestore
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    statusProvider.markStatusItemViewed(
      statusOwnerUid: _currentStatus.uid,
      statusItemId: item.id,
    );

    if (item.type == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(item.content))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            final duration = _videoController!.value.duration;
            _animController.duration = duration > Duration.zero ? duration : const Duration(seconds: 5);
            _videoController!.play();
            _animController.forward();
          }
        }).catchError((e) {
          debugPrint('Error loading status video: $e');
          _animController.duration = const Duration(seconds: 5);
          _animController.forward();
        });
    } else {
      _animController.duration = const Duration(seconds: 5);
      _animController.forward();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentItems.length - 1) {
      _loadStory(storyIndex: _currentStoryIndex + 1);
    } else {
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _loadStory(storyIndex: _currentStoryIndex - 1);
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
      });
      _loadStory(storyIndex: 0);
    } else {
      _loadStory(storyIndex: 0);
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.statuses.length - 1) {
      setState(() {
        _currentUserIndex++;
      });
      _loadStory(storyIndex: 0);
    } else {
      Navigator.pop(context);
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _animController.stop();
      _videoController?.pause();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _animController.forward();
      _videoController?.play();
    }
  }

  String _formatStatusTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  void _showDeleteDialog(BuildContext parentContext, String itemId) {
    _pause();
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete this status?'),
        content: const Text('This status will be deleted for everyone who received it.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _resume();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final statusProvider = Provider.of<StatusProvider>(parentContext, listen: false);
              await statusProvider.deleteStatusItem(itemId);

              if (!mounted) return;
              if (_currentItems.length <= 1) {
                Navigator.of(context).pop();
              } else {
                _nextStory();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showViewersSheet(BuildContext context, StatusItemModel item) {
    _pause();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Viewed by ${item.viewers.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _showDeleteDialog(context, item.id);
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                if (item.viewers.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No views yet',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: item.viewers.length,
                      itemBuilder: (context, index) {
                        final viewerUid = item.viewers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[700],
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            viewerUid,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    if (item == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0078FF))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width * 0.3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // Status Content (Text, Image, Video)
            Positioned.fill(
              child: _buildStoryContent(item),
            ),

            // Top Gradient Overlay for readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Top Segmented Progress Bars & User Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  children: [
                    // Segmented Progress Bar
                    Row(
                      children: List.generate(_currentItems.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                double progress = 0.0;
                                if (index < _currentStoryIndex) {
                                  progress = 1.0;
                                } else if (index == _currentStoryIndex) {
                                  progress = _animController.value;
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white30,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 2.5,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Header Bar (Avatar, Name, Time, Menu/Close)
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[700],
                          backgroundImage: _currentStatus.userImage.isNotEmpty ? CachedNetworkImageProvider(_currentStatus.userImage) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isMyStatus ? 'My Status' : _currentStatus.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatStatusTime(item.createdAt),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (_isMyStatus)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (val) {
                              if (val == 'delete') {
                                _showDeleteDialog(context, item.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Caption (if any)
            if (item.caption != null && item.caption!.isNotEmpty)
              Positioned(
                bottom: _isMyStatus ? 50 : 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.caption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),

            // Bottom Views Count for "My Status"
            if (_isMyStatus)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showViewersSheet(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_outlined, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${item.viewers.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StatusItemModel item) {
    if (item.type == 'text') {
      return Container(
        color: Color(item.backgroundColor),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: Alignment.center,
        child: Text(
          item.content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: item.fontFamily == 'Serif'
                ? 'serif'
                : (item.fontFamily == 'Monospace' ? 'monospace' : null),
            fontStyle: item.fontFamily == 'Cursive' ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
    } else if (item.type == 'video') {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0078FF)));
    } else {
      return Center(
        child: CachedNetworkImage(
          imageUrl: item.content,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF0078FF))),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      );
    }
  }
}
