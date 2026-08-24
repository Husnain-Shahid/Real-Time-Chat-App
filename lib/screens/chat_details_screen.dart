import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/database_service.dart';
import 'active_call_screen.dart';
import 'chat_screen.dart';
import 'create_group_info_screen.dart';
import '../models/user_model.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String receiverId;

  const ChatDetailsScreen({
    super.key,
    required this.receiverId,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isFavorite = false;
  bool _isMuted = false;

  late final String _chatRoomId;
  late final Stream<DocumentSnapshot> _userStream;
  late final Stream<QuerySnapshot> _mediaStream;
  late final Stream<QuerySnapshot> _commonGroupsStream;

  @override
  void initState() {
    super.initState();
    _chatRoomId = _databaseService.getChatRoomId(_currentUserId, widget.receiverId);
    _userStream = FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots();
    _mediaStream = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_chatRoomId)
        .collection('messages')
        .where('mediaUrl', isNull: false)
        .snapshots();
    _commonGroupsStream = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('isGroup', isEqualTo: true)
        .where('users', arrayContains: _currentUserId)
        .snapshots();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear this chat?'),
          content: const Text('Messages will be deleted from this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _databaseService.clearChat(widget.receiverId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat cleared')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to clear chat: $e')),
                    );
                  }
                }
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact options')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0078FF)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User details not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String contactName = userData['name'] ?? 'Contact';
          final String phoneNumber = userData['phoneNumber'] ?? userData['email'] ?? '+92 340 3912622';
          final String avatarUrl = userData['profileImage'] ?? '';
          final String aboutText = userData['about'] ?? 'Hey there! I am using Messenger.';

          final String initials = contactName.isNotEmpty
              ? contactName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
              : 'U';

          return ListView(
            children: [
              // Contact Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFFE5F1FF),
                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      onBackgroundImageError: avatarUrl.isNotEmpty ? (_, _) {} : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0078FF),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      contactName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last seen today at 9:10 am',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Action Buttons Row (Audio, Video, Search)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.call_outlined,
                          label: 'Audio',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveCallScreen(
                                  contactName: contactName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.videocam_outlined,
                          label: 'Video',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveCallScreen(
                                  contactName: contactName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.search,
                          label: 'Search',
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 16, color: Color(0xFFF0F2F5), thickness: 8),

              // About / Status Section
              if (aboutText.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aboutText,
                        style: const TextStyle(fontSize: 15.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'December 15, 2025',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE9EDEF)),
              ],

              // Media, links, and docs Section (Live Stream from chat messages!)
              StreamBuilder<QuerySnapshot>(
                stream: _mediaStream,
                builder: (context, mediaSnap) {
                  List<String> mediaUrls = [];
                  if (mediaSnap.hasData) {
                    for (var doc in mediaSnap.data!.docs) {
                      final mData = doc.data() as Map<String, dynamic>;
                      final url = (mData['mediaUrl'] ?? mData['imageUrl']) as String?;
                      if (url != null && url.isNotEmpty) {
                        mediaUrls.add(url);
                      }
                    }
                  }

                  final int mediaCount = mediaUrls.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: const Text(
                          'Media, links, and docs',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$mediaCount', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 20, color: Colors.grey[600]),
                          ],
                        ),
                        onTap: () {},
                      ),
                      if (mediaUrls.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                            itemCount: mediaUrls.length,
                            itemBuilder: (context, idx) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[200],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    mediaUrls[idx],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 12),
                          child: Text(
                            'No media shared yet',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const Divider(height: 1, color: Color(0xFFE9EDEF)),

              // Settings & Storage Options
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.photo_library_outlined, color: Colors.black87, size: 24),
                title: const Text('Manage storage', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                subtitle: Text('309.9 MB', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                onTap: () {},
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 24),
                title: const Text('Notifications', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                subtitle: Text(_isMuted ? 'Muted' : 'Default', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                trailing: Switch(
                  value: !_isMuted,
                  activeThumbColor: const Color(0xFF0078FF),
                  onChanged: (val) {
                    setState(() {
                      _isMuted = !val;
                    });
                  },
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.image_outlined, color: Colors.black87, size: 24),
                title: const Text('Media visibility', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                onTap: () {},
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.lock_outline, color: Colors.black87, size: 24),
                title: const Text('Encryption', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                subtitle: Text(
                  'Messages and calls are end-to-end encrypted. Tap to verify.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                onTap: () {},
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.timer_outlined, color: Colors.black87, size: 24),
                title: const Text('Disappearing messages', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                subtitle: Text('Off', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                onTap: () {},
              ),

              const Divider(height: 16, color: Color(0xFFF0F2F5), thickness: 8),

              // ==================== GROUPS IN COMMON ====================
              StreamBuilder<QuerySnapshot>(
                stream: _commonGroupsStream,
                builder: (context, groupSnap) {
                  List<QueryDocumentSnapshot> commonGroups = [];
                  if (groupSnap.hasData) {
                    commonGroups = groupSnap.data!.docs.where((doc) {
                      final gData = doc.data() as Map<String, dynamic>;
                      final users = List<String>.from(gData['users'] ?? []);
                      return users.contains(widget.receiverId);
                    }).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Text(
                          '${commonGroups.length} Groups in common',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Create group with contact option
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0078FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group_add, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          'Create group with $contactName',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateGroupInfoScreen(
                                selectedMembers: [
                                  UserModel.fromMap({
                                    'uid': widget.receiverId,
                                    ...userData,
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // List of actual common groups
                      ...commonGroups.map((gDoc) {
                        final gData = gDoc.data() as Map<String, dynamic>;
                        final gName = gData['groupName'] as String? ?? 'Group';
                        final gImage = gData['groupImage'] as String? ?? '';
                        final users = List<String>.from(gData['users'] ?? []);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFE5F1FF),
                            backgroundImage: gImage.isNotEmpty ? NetworkImage(gImage) : null,
                            onBackgroundImageError: gImage.isNotEmpty ? (_, _) {} : null,
                            child: gImage.isEmpty
                                ? const Icon(Icons.groups, size: 24, color: Color(0xFF0078FF))
                                : null,
                          ),
                          title: Text(
                            gName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          subtitle: Text(
                            '${users.length} members',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          onTap: () {
                            final chat = ChatModel(
                              id: gDoc.id,
                              chatRoomId: gDoc.id,
                              name: gName,
                              avatarUrl: gImage,
                              isGroup: true,
                              lastMessage: gData['lastMessage'] ?? '',
                              time: '',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chat: chat,
                                  receiverId: gDoc.id,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  );
                },
              ),

              const Divider(height: 16, color: Color(0xFFF0F2F5), thickness: 8),

              // Favorites & Action Options
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.black87,
                  size: 24,
                ),
                title: Text(
                  _isFavorite ? 'Added to Favourites' : 'Add to Favourites',
                  style: const TextStyle(fontSize: 15.5, color: Colors.black87),
                ),
                onTap: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isFavorite ? 'Added to Favourites' : 'Removed from Favourites'),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.photo_library_outlined, color: Colors.black87, size: 24),
                title: const Text('Add to list', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                onTap: () {},
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.remove_circle_outline, color: Color(0xFFD32F2F), size: 24),
                title: const Text(
                  'Clear chat',
                  style: TextStyle(color: Color(0xFFD32F2F), fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
                onTap: _confirmClearChat,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.block, color: Color(0xFFD32F2F), size: 24),
                title: Text(
                  'Block $contactName',
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$contactName blocked')),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.thumb_down_outlined, color: Color(0xFFD32F2F), size: 24),
                title: Text(
                  'Report $contactName',
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$contactName reported')),
                  );
                },
              ),

              const SizedBox(height: 36),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9EDEF), width: 1),
              ),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}