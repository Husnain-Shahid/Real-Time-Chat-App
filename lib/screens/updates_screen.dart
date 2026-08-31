import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/status_model.dart';
import '../provider/status_provider.dart';
import '../provider/home_provider.dart';
import '../services/image_picker_service.dart';
import 'create_text_status_screen.dart';
import 'status_media_preview_screen.dart';
import 'status_viewer_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> with AutomaticKeepAliveClientMixin {
  final ImagePickerService _imagePickerService = ImagePickerService();
  bool _isViewedExpanded = true;

  @override
  bool get wantKeepAlive => true;

  void _showMediaPickerOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: 20,
              spacing: 24,
              children: [
                _buildOptionItem(
                  icon: Icons.camera_alt,
                  color: Colors.pink,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final xFile = await _imagePickerService.pickImageXFile(source: ImageSource.camera);
                    if (xFile != null) {
                      final bytes = await xFile.readAsBytes();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatusMediaPreviewScreen(
                            bytes: bytes,
                            fileName: xFile.name,
                            mediaType: 'image',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildOptionItem(
                  icon: Icons.photo_library,
                  color: Colors.purple,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final xFile = await _imagePickerService.pickImageXFile(source: ImageSource.gallery);
                    if (xFile != null) {
                      final bytes = await xFile.readAsBytes();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatusMediaPreviewScreen(
                            bytes: bytes,
                            fileName: xFile.name,
                            mediaType: 'image',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildOptionItem(
                  icon: Icons.videocam,
                  color: Colors.deepOrange,
                  label: 'Video',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final xFile = await _imagePickerService.pickVideoXFile(source: ImageSource.gallery);
                    if (xFile != null) {
                      final bytes = await xFile.readAsBytes();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatusMediaPreviewScreen(
                            bytes: bytes,
                            fileName: xFile.name,
                            mediaType: 'video',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildOptionItem(
                  icon: Icons.edit,
                  color: const Color(0xFF0078FF),
                  label: 'Text Status',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateTextStatusScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return DateFormat('h:mm a').format(dateTime).toLowerCase();
    } else if (now.difference(dateTime).inDays == 1 || (now.day - dateTime.day == 1)) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final statusProvider = Provider.of<StatusProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final String myAvatarUrl = currentUser?.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb';

    // Sync chat contact UIDs to StatusProvider for real-time contact filtering
    final contactUids = <String>{};
    for (var doc in homeProvider.chatDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['users'] is List) {
        final users = data['users'] as List;
        for (var u in users) {
          if (u is String && u != currentUserId && u.isNotEmpty) {
            contactUids.add(u);
          }
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      statusProvider.updateContactUids(contactUids);
    });

    final myStatus = statusProvider.myStatus;
    final recentStatuses = statusProvider.recentStatuses;
    final viewedStatuses = statusProvider.viewedStatuses;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Updates',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'status_privacy', child: Text('Status privacy')),
              const PopupMenuItem(value: 'create_channel', child: Text('Create channel')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Section Title: Status
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // "My Status" ListTile
          _buildMyStatusTile(myStatus, myAvatarUrl, currentUserId),

          // Recent updates section
          if (recentStatuses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                'Recent updates',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ...recentStatuses.asMap().entries.map((entry) {
              return _buildContactStatusTile(
                entry.value,
                entry.key,
                recentStatuses,
                currentUserId,
              );
            }),
          ],

          // Viewed updates section
          if (viewedStatuses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isViewedExpanded = !_isViewedExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Viewed updates',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Icon(
                      _isViewedExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_isViewedExpanded)
              ...viewedStatuses.asMap().entries.map((entry) {
                return _buildContactStatusTile(
                  entry.value,
                  entry.key,
                  viewedStatuses,
                  currentUserId,
                );
              }),
          ],

          // Empty state for contacts
          if (recentStatuses.isEmpty && viewedStatuses.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.amp_stories_outlined, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 10),
                    Text(
                      'No status updates yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Statuses from your contacts will appear here',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Pencil FAB (mini)
          FloatingActionButton(
            heroTag: 'pencil_update',
            mini: true,
            backgroundColor: const Color(0xFFF0F2F5),
            elevation: 3,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTextStatusScreen()),
              );
            },
            child: const Icon(Icons.edit, color: Colors.black87, size: 20),
          ),
          const SizedBox(height: 14),
          // Camera FAB (rounded squircle)
          FloatingActionButton(
            heroTag: 'camera_update',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF0078FF),
            elevation: 4,
            onPressed: () => _showMediaPickerOptions(context),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  // "My Status" ListTile (matching WhatsApp vertical layout)
  Widget _buildMyStatusTile(StatusModel? myStatus, String avatarUrl, String currentUserId) {
    final bool hasActive = myStatus != null && myStatus.hasActiveStatus;

    return RepaintBoundary(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            if (hasActive)
              _SegmentedStatusAvatar(
                status: myStatus,
                currentUserId: currentUserId,
                radius: 25,
              )
            else
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
              ),
            if (!hasActive)
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0078FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        title: Text(
          hasActive ? 'My status' : 'Add status',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          hasActive
              ? _formatRelativeTime(myStatus.latestItem?.createdAt)
              : 'Disappears after 24 hours',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: hasActive
            ? IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onPressed: () => _showMediaPickerOptions(context),
              )
            : null,
        onTap: () {
          if (hasActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatusViewerScreen(
                  statuses: [myStatus],
                  initialUserIndex: 0,
                ),
              ),
            );
          } else {
            _showMediaPickerOptions(context);
          }
        },
      ),
    );
  }

  // Contact status ListTile with segmented circle ring
  Widget _buildContactStatusTile(
    StatusModel status,
    int index,
    List<StatusModel> statusList,
    String currentUserId,
  ) {
    final latestItem = status.latestItem;

    return RepaintBoundary(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: _SegmentedStatusAvatar(
          status: status,
          currentUserId: currentUserId,
          radius: 25,
        ),
        title: Text(
          status.userName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          _formatRelativeTime(latestItem?.createdAt),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatusViewerScreen(
                statuses: statusList,
                initialUserIndex: index,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom segmented avatar widget with segmented green/grey status ring
class _SegmentedStatusAvatar extends StatelessWidget {
  final StatusModel status;
  final String currentUserId;
  final double radius;

  const _SegmentedStatusAvatar({
    required this.status,
    required this.currentUserId,
    this.radius = 25,
  });

  @override
  Widget build(BuildContext context) {
    final activeItems = status.activeItems;
    final count = activeItems.length;
    final viewedList = activeItems.map((item) => item.isViewedBy(currentUserId)).toList();

    return RepaintBoundary(
      child: SizedBox(
        width: radius * 2 + 8,
        height: radius * 2 + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Segmented Ring Custom Painter
            CustomPaint(
              size: Size(radius * 2 + 8, radius * 2 + 8),
              painter: _SegmentedRingPainter(
                count: count,
                viewedList: viewedList,
                strokeWidth: 2.5,
              ),
            ),
            // User Avatar
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
              backgroundImage: status.userImage.isNotEmpty ? CachedNetworkImageProvider(status.userImage) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to draw segmented arcs representing each active status item
class _SegmentedRingPainter extends CustomPainter {
  final int count;
  final List<bool> viewedList;
  final double strokeWidth;

  _SegmentedRingPainter({
    required this.count,
    required this.viewedList,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (count == 1) {
      paint.color = (viewedList.isNotEmpty && viewedList.first)
          ? Colors.grey.shade400
          : const Color(0xFF0078FF);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    const double gapDegrees = 6.0;
    final double totalGapDegrees = count * gapDegrees;
    final double arcDegrees = (360.0 - totalGapDegrees) / count;
    final double gapRadian = gapDegrees * (3.141592653589793 / 180.0);
    final double arcRadian = arcDegrees * (3.141592653589793 / 180.0);

    double startAngle = -3.141592653589793 / 2; // start at 12 o'clock

    for (int i = 0; i < count; i++) {
      final isViewed = (i < viewedList.length) ? viewedList[i] : false;
      paint.color = isViewed ? Colors.grey.shade400 : const Color(0xFF0078FF);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapRadian / 2),
        arcRadian,
        false,
        paint,
      );

      startAngle += arcRadian + gapRadian;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.count != count || oldDelegate.viewedList != viewedList;
  }
}