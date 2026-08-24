import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../provider/home_provider.dart';
import '../widget/custom_nav_bar.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';
import 'updates_screen.dart';
import 'calls_screen.dart';
import 'profile_screen.dart';
import 'select_contact_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  late PageController _pageController;

  static const List<Widget> _screens = [
    ChatHomeView(),
    UpdatesScreen(),
    CallsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = Provider.of<HomeProvider>(context, listen: false).currentIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.currentIndex != index) {
      homeProvider.setBottomNavIndex(index);
    }
  }

  void _onBottomNavTapped(int index) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.setBottomNavIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // Keep page controller synced in case provider changed index from outside
    if (_pageController.hasClients && _pageController.page?.round() != homeProvider.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients && _pageController.page?.round() != homeProvider.currentIndex) {
          _pageController.animateToPage(
            homeProvider.currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: homeProvider.currentIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}

class ChatHomeView extends StatefulWidget {
  const ChatHomeView({super.key});

  @override
  State<ChatHomeView> createState() => _ChatHomeViewState();
}

class _ChatHomeViewState extends State<ChatHomeView> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatChatTime(dynamic rawTimestamp, String fallbackTime) {
    if (rawTimestamp == null) return fallbackTime;

    final DateTime dateTime;
    if (rawTimestamp is Timestamp) {
      dateTime = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      dateTime = rawTimestamp;
    } else {
      return fallbackTime;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else if (today.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // e.g. Monday
    } else {
      return DateFormat('dd/MM/yy').format(dateTime); // e.g. 21/08/26
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final unreadChatsCount = homeProvider.totalUnreadChatsCount;

    final isSelecting = homeProvider.isSelectingChat;

    // Find selected chat details if selecting
    String selectedReceiverId = '';
    String selectedDisplayName = '';
    bool selectedIsFav = false;
    if (isSelecting) {
      final selectedDoc = homeProvider.chatDocs.firstWhere(
        (doc) => doc.id == homeProvider.selectedChatRoomId,
        orElse: () => homeProvider.chatDocs.first,
      );
      final data = selectedDoc.data() as Map<String, dynamic>;
      final users = data['users'] as List? ?? [];
      selectedReceiverId = users.firstWhere(
        (id) => id != currentUserId,
        orElse: () => (users.isNotEmpty ? users.first : ''),
      );
      final receiver = homeProvider.userCache[selectedReceiverId];
      selectedDisplayName = receiver?.name ?? 'Chat';
      final favoritesList = data['favorites'] as List? ?? [];
      selectedIsFav = favoritesList.contains(currentUserId) || data['favorite_$currentUserId'] == true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isSelecting
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => homeProvider.clearChatSelection(),
              ),
              title: const Text(
                '1',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: selectedIsFav ? 'Unfavorite' : 'Favorite',
                  icon: Icon(
                    selectedIsFav ? Icons.star : Icons.star_border,
                    color: selectedIsFav ? Colors.amber[700] : Colors.black87,
                  ),
                  onPressed: () => homeProvider.toggleFavoriteSelectedChat(
                    selectedReceiverId,
                    selectedIsFav,
                  ),
                ),
                IconButton(
                  tooltip: 'Clear Chat',
                  icon: const Icon(Icons.cleaning_services_outlined, color: Colors.black87),
                  onPressed: () => _showClearChatDialog(
                    context,
                    homeProvider,
                    selectedReceiverId,
                    selectedDisplayName,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Chat',
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEA0038)),
                  onPressed: () => _showDeleteChatDialog(
                    context,
                    homeProvider,
                    selectedReceiverId,
                    selectedDisplayName,
                  ),
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Chattrix',
                style: TextStyle(
                  color: Color(0xFF0078FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'new_group', child: Text('New group')),
                    const PopupMenuItem(value: 'new_broadcast', child: Text('New broadcast')),
                    const PopupMenuItem(value: 'linked_devices', child: Text('Linked devices')),
                    const PopupMenuItem(value: 'starred', child: Text('Starred messages')),
                    const PopupMenuItem(value: 'settings', child: Text('Settings')),
                  ],
                ),
              ],
            ),
      body: Column(
        children: [
          // Search Bar (Ask Meta AI or Search)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => homeProvider.setSearchQuery(val),
                      decoration: const InputDecoration(
                        hintText: 'Ask Meta AI or Search',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        homeProvider.setSearchQuery('');
                      },
                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
                    ),
                ],
              ),
            ),
          ),
          // Filter Chips (All, Unread, Favorites, Groups)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All',
                  isSelected: homeProvider.selectedFilter == 'All',
                  onTap: () => homeProvider.setSelectedFilter('All'),
                ),
                _buildFilterChip(
                  context,
                  label: unreadChatsCount > 0 ? 'Unread $unreadChatsCount' : 'Unread',
                  isSelected: homeProvider.selectedFilter == 'Unread',
                  onTap: () => homeProvider.setSelectedFilter('Unread'),
                ),
                _buildFilterChip(
                  context,
                  label: 'Favorites',
                  isSelected: homeProvider.selectedFilter == 'Favorites',
                  onTap: () => homeProvider.setSelectedFilter('Favorites'),
                ),
                _buildFilterChip(
                  context,
                  label: 'Groups',
                  isSelected: homeProvider.selectedFilter == 'Groups',
                  onTap: () => homeProvider.setSelectedFilter('Groups'),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F2F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // const Divider(height: 1, color: Color(0xFFF0F2F5)),

          // Chat List View
          Expanded(
            child: homeProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0078FF)))
                : homeProvider.chatDocs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                homeProvider.selectedFilter == 'Unread'
                                    ? 'No unread chats'
                                    : 'No chats yet',
                                style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap the green button below to start a new chat!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: homeProvider.chatDocs.length,
                        itemBuilder: (context, index) {
                          final chatRoomDoc = homeProvider.chatDocs[index];
                          final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
                          final users = chatRoomData['users'] as List? ?? [];
                          
                          final bool isGroup = chatRoomData['isGroup'] == true;
                          
                          // Determine the contact / group UID
                          final receiverId = isGroup
                              ? chatRoomDoc.id
                              : users.firstWhere(
                                  (id) => id != currentUserId,
                                  orElse: () => (users.isNotEmpty ? users.first : ''),
                                );
                          
                          if (receiverId.isEmpty) return const SizedBox.shrink();

                          final int unreadCount = (chatRoomData['unreadCount_$currentUserId'] as num?)?.toInt() ?? 0;
                          final receiver = isGroup ? null : homeProvider.userCache[receiverId];

                          final isSelfChat = !isGroup && receiverId == currentUserId;
                          final displayName = isGroup
                              ? (chatRoomData['groupName'] as String? ?? 'Group')
                              : (isSelfChat
                                  ? '${receiver?.name ?? 'Message yourself'} (You)'
                                  : (receiver?.name.isNotEmpty == true ? receiver!.name : 'Chat'));
                          final avatarUrl = isGroup
                              ? (chatRoomData['groupImage'] as String? ?? '')
                              : (receiver?.profileImage ?? '');

                          final lastMessageText = chatRoomData['lastMessage'] ?? 'Tap to chat';
                          final dynamic timestamp = chatRoomData['lastMessageTimestamp'];
                          final timeText = _formatChatTime(timestamp, chatRoomData['lastMessageTime'] ?? '');
                          final lastSenderId = chatRoomData['lastSenderId'] ?? '';
                          final isMe = lastSenderId == currentUserId;
                          final isLastMessageRead = chatRoomData['isLastMessageRead'] ?? true;

                          final chat = ChatModel(
                            id: receiverId,
                            chatRoomId: chatRoomDoc.id,
                            name: displayName,
                            lastMessage: lastMessageText,
                            time: timeText,
                            avatarUrl: avatarUrl,
                            unreadCount: unreadCount,
                            isGroup: isGroup,
                          );

                          final isSelected = homeProvider.selectedChatRoomId == chatRoomDoc.id;

                          return _ChatListTile(
                            chat: chat,
                            receiverId: receiverId,
                            isMe: isMe,
                            unreadCount: unreadCount,
                            isLastMessageRead: isLastMessageRead,
                            isSelected: isSelected,
                            onLongPress: () {
                              homeProvider.selectChat(chatRoomDoc.id);
                            },
                            onTap: () {
                              if (homeProvider.isSelectingChat) {
                                if (isSelected) {
                                  homeProvider.clearChatSelection();
                                } else {
                                  homeProvider.selectChat(chatRoomDoc.id);
                                }
                                return;
                              }

                              _databaseService.markMessagesAsRead(receiverId);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chat: chat,
                                    receiverId: receiverId,
                                  ),
                                ),
                              ).then((_) {
                                _databaseService.markMessagesAsRead(receiverId);
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: isSelecting
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 12),
                // New Message FAB
                FloatingActionButton(
                  heroTag: 'new_chat_fab',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: const Color(0xFF0078FF),
                  elevation: 4,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectContactScreen()),
                    );
                  },
                  child: const Icon(Icons.add_comment, color: Colors.white, size: 24),
                ),
              ],
            ),
    );
  }

  void _showDeleteChatDialog(
    BuildContext context,
    HomeProvider homeProvider,
    String receiverId,
    String displayName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete chat with $displayName?'),
        content: const Text(
          'Messages, photos, videos, and audio in this chat will be permanently deleted from servers and cannot be recovered.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await homeProvider.deleteSelectedChat(receiverId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat with $displayName deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete chat. Please try again.')),
                  );
                }
              }
            },
            child: const Text(
              'Delete chat',
              style: TextStyle(color: Color(0xFFEA0038), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(
    BuildContext context,
    HomeProvider homeProvider,
    String receiverId,
    String displayName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear chat with $displayName?'),
        content: const Text(
          'All messages, photos, videos, and media in this chat will be deleted. The conversation entry will remain on your Home screen.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await homeProvider.clearSelectedChat(receiverId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat with $displayName cleared')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to clear chat. Please try again.')),
                  );
                }
              }
            },
            child: const Text(
              'Clear chat',
              style: TextStyle(color: Color(0xFFEA0038), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5F1FF) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0078FF) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final String receiverId;
  final bool isMe;
  final int unreadCount;
  final bool isLastMessageRead;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatListTile({
    required this.chat,
    required this.receiverId,
    required this.isMe,
    required this.unreadCount,
    this.isLastMessageRead = true,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    return Container(
      color: isSelected ? const Color(0xFFE5F1FF) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE5F1FF),
              backgroundImage: chat.avatarUrl.isNotEmpty ? NetworkImage(chat.avatarUrl) : null,
              onBackgroundImageError: chat.avatarUrl.isNotEmpty ? (_, _) {} : null,
              child: chat.avatarUrl.isEmpty
                  ? (chat.isGroup
                      ? const Icon(Icons.groups, size: 28, color: Color(0xFF0078FF))
                      : Text(
                          chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0078FF)),
                        ))
                  : null,
            ),
            if (isSelected)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0078FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          chat.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              if (isMe && chat.lastMessage != 'Tap to chat' && chat.lastMessage != 'No messages yet') ...[
                Icon(
                  Icons.done_all,
                  size: 16,
                  color: isLastMessageRead ? const Color(0xFF0078FF) : const Color(0xFF8696A0),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  isMe && !chat.lastMessage.startsWith('You:') && chat.lastMessage != 'Tap to chat' && chat.lastMessage != 'No messages yet'
                      ? 'You: ${chat.lastMessage}'
                      : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat.time,
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? const Color(0xFF0078FF) : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                decoration: const BoxDecoration(
                  color: Color(0xFF0078FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with your community and stay informed',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}