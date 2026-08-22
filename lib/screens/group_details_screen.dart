import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'add_group_members_screen.dart';
import 'chat_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String chatRoomId;

  const GroupDetailsScreen({
    super.key,
    required this.chatRoomId,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSearchingMembers = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDirectChatWithMember(UserModel member) {
    if (member.uid == _currentUserId) return;

    final chat = ChatModel(
      id: member.uid,
      name: member.name,
      lastMessage: 'Tap to chat',
      time: '',
      avatarUrl: member.profileImage,
      isGroup: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chat: chat,
          receiverId: member.uid,
        ),
      ),
    );
  }

  void _showMemberOptions(UserModel member, String createdBy, String groupName) {
    if (member.uid == _currentUserId) return;

    final bool isCurrentUserAdmin = createdBy == _currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_outlined, color: Color(0xFF00A884)),
                  title: Text('Message ${member.name}'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openDirectChatWithMember(member);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.black87),
                  title: Text('View ${member.name}'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                ),
                if (isCurrentUserAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: Color(0xFFD32F2F)),
                    title: Text(
                      'Remove ${member.name}',
                      style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmRemoveMember(member, groupName);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemoveMember(UserModel member, String groupName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Remove ${member.name}?'),
          content: Text('Are you sure you want to remove ${member.name} from "$groupName"?'),
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
                  await _databaseService.removeGroupMember(
                    chatRoomId: widget.chatRoomId,
                    memberUid: member.uid,
                    memberName: member.name,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${member.name} was removed from the group')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to remove member: $e')),
                    );
                  }
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmExitGroup(String groupName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Exit group?'),
          content: Text('Are you sure you want to exit "$groupName"?'),
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
                  await _databaseService.exitGroup(chatRoomId: widget.chatRoomId);
                  if (mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to exit group: $e')),
                    );
                  }
                }
              },
              child: const Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear chat?'),
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
                  await _databaseService.clearChat(widget.chatRoomId);
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
    return StreamBuilder<DocumentSnapshot>(
      stream: _databaseService.getChatRoomStream(widget.chatRoomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00A884))),
          );
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final String groupName = roomData['groupName'] ?? 'Group';
        final String groupImage = roomData['groupImage'] ?? '';
        final String createdBy = roomData['createdBy'] ?? '';
        final List<String> memberUids = List<String>.from(roomData['users'] ?? []);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFC7E8FA),
                  backgroundImage: groupImage.isNotEmpty ? NetworkImage(groupImage) : null,
                  onBackgroundImageError: groupImage.isNotEmpty ? (_, _) {} : null,
                  child: groupImage.isEmpty
                      ? const Icon(Icons.groups, color: Color(0xFF008069), size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_2, color: Colors.black87),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group QR code ready')),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (value) {
                  if (value == 'invite') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'invite',
                    child: Text('Invite link'),
                  ),
                  const PopupMenuItem(
                    value: 'media',
                    child: Text('Media, links, and docs'),
                  ),
                  const PopupMenuItem(
                    value: 'search',
                    child: Text('Search'),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            children: [
              // Top Banner: Create a similar group
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add, color: Colors.white, size: 22),
                ),
                title: const Text(
                  'Create a similar group',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                ),
                subtitle: Text(
                  'Start with the same members that you can add or remove.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddGroupMembersScreen(
                        chatRoomId: widget.chatRoomId,
                        currentMemberUids: memberUids,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFE9EDEF), thickness: 1),

              // Members Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${memberUids.length} members',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSearchingMembers ? Icons.close : Icons.search,
                        color: Colors.black54,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _isSearchingMembers = !_isSearchingMembers;
                          if (!_isSearchingMembers) {
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Member Search Bar
              if (_isSearchingMembers)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00A884), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),

              // Add members action tile
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                ),
                title: const Text(
                  'Add members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddGroupMembersScreen(
                        chatRoomId: widget.chatRoomId,
                        currentMemberUids: memberUids,
                      ),
                    ),
                  );
                },
              ),

              // Invite via link or QR code action tile
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link, color: Colors.white, size: 20),
                ),
                title: const Text(
                  'Invite via link or QR code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied')),
                  );
                },
              ),

              // Members List
              FutureBuilder<List<UserModel>>(
                future: _databaseService.getGroupMembers(memberUids),
                builder: (context, memberSnapshot) {
                  if (!memberSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF00A884))),
                    );
                  }

                  var members = memberSnapshot.data!;
                  if (_searchQuery.isNotEmpty) {
                    members = members
                        .where((m) => m.name.toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  // Put current user "You" first
                  members.sort((a, b) {
                    if (a.uid == _currentUserId) return -1;
                    if (b.uid == _currentUserId) return 1;
                    return a.name.compareTo(b.name);
                  });

                  return Column(
                    children: members.map((member) {
                      final bool isMe = member.uid == _currentUserId;
                      final bool isMemberCreator = member.uid == createdBy;

                      String initials = member.name.isNotEmpty
                          ? member.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                          : '?';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                        onTap: () => _showMemberOptions(member, createdBy, groupName),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFC7E8FA),
                          backgroundImage: member.profileImage.isNotEmpty
                              ? NetworkImage(member.profileImage)
                              : null,
                          onBackgroundImageError: member.profileImage.isNotEmpty ? (_, _) {} : null,
                          child: member.profileImage.isEmpty
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF008069),
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          isMe ? 'You' : member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: isMe
                            ? const Text(
                                'Add member tag',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF00A884),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : (member.about.isNotEmpty
                                ? Text(
                                    member.about,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  )
                                : null),
                        trailing: isMemberCreator
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCF8C6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Group Admin',
                                  style: TextStyle(
                                    color: Color(0xFF008069),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      );
                    }).toList(),
                  );
                },
              ),

              const Divider(height: 16, color: Color(0xFFE9EDEF), thickness: 1),

              // Options list below members
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.format_list_bulleted, color: Colors.black87, size: 24),
                title: const Text('View member changes', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                onTap: () {},
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.favorite_border, color: Colors.black87, size: 24),
                title: const Text('Add to Favourites', style: TextStyle(fontSize: 15.5, color: Colors.black87)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to Favourites')),
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
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 24),
                title: const Text(
                  'Exit group',
                  style: TextStyle(color: Color(0xFFD32F2F), fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
                onTap: () => _confirmExitGroup(groupName),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                leading: const Icon(Icons.thumb_down_outlined, color: Color(0xFFD32F2F), size: 24),
                title: const Text(
                  'Report group',
                  style: TextStyle(color: Color(0xFFD32F2F), fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group reported')),
                  );
                },
              ),

              const SizedBox(height: 36),
            ],
          ),
        );
      },
    );
  }
}
