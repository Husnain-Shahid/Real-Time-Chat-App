import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';
import 'updates_screen.dart';
import '../widget/custom_nav_bar.dart'; // Import your professional nav bar widget
import 'calls_screen.dart'; // <--- Import your newly created calls screen
import 'profile_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // List of screens corresponding to each bottom navigation tab
  late final List<Widget> _screens = [
    const ChatHomeView(),
    const UpdatesScreen(),
    const PlaceholderScreen(title: 'Communities'),
    const CallsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each tab when switching back and forth
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// -----------------------------------------------------------------
// Chat Home View (Your primary WhatsApp chat list interface)
// -----------------------------------------------------------------
class ChatHomeView extends StatefulWidget {
  const ChatHomeView({super.key});

  @override
  State<ChatHomeView> createState() => _ChatHomeViewState();
}

class _ChatHomeViewState extends State<ChatHomeView> {
  String _selectedFilter = 'All';

  final List<ChatModel> _chats = [
    ChatModel(
      name: 'İlkyazım ♡ (You)',
      lastMessage: 'https://www.instagram.com/re...',
      time: 'Yesterday',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      isPinned: true,
    ),
    ChatModel(
      name: 'Ahsan Iqbal',
      lastMessage: '5th Semester.zip',
      time: '8:37 AM',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      isUnread: true,
    ),
    ChatModel(
      name: 'Ahmad Hassan',
      lastMessage: 'Ahmad Hassan reacted 👍 to "Suba kr l..."',
      time: 'Yesterday',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
    ),
    ChatModel(
      name: 'Abdullah Khan',
      lastMessage: 'Voice call',
      time: 'Yesterday',
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce',
    ),
    ChatModel(
      name: 'SP24-BSE-A',
      lastMessage: "Class Discussion  ‣  insha'Allah",
      time: 'Yesterday',
      avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe',
      isGroup: true,
    ),
    ChatModel(
      name: 'Abdullah Javed',
      lastMessage: 'Okk',
      time: 'Yesterday',
      avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61',
    ),
    ChatModel(
      name: 'Shehzad Ali',
      lastMessage: 'Sir i have shared my Week 6 Internship...',
      time: 'Yesterday',
      avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
      isUnread: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'WhatsApp',
          style: TextStyle(
            color: Color(0xFF075E54),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new_group', child: Text('New group')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search/Meta AI Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'Ask Meta AI or Search',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Unread'),
                _buildFilterChip('Favorites'),
                _buildFilterChip('Groups'),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFF0F2F5),
                  child: const Icon(Icons.add, size: 18, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Chat List View
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.archive_outlined, color: Colors.grey),
                  title: const Text(
                    'Archived',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Text(
                    '3',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {},
                ),
                ..._chats.map((chat) => ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(chat.avatarUrl),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: chat.isUnread ? const Color(0xFF25D366) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        if (!chat.isGroup) ...[
                          const Icon(Icons.done_all, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: chat.isUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: chat.isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (chat.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.push_pin, size: 14, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chat: chat),
                      ),
                    );
                  },
                )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'edit_btn',
            mini: true,
            backgroundColor: const Color(0xFFF0F2F5),
            elevation: 2,
            onPressed: () {},
            child: const Icon(Icons.edit, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'chat_btn',
            backgroundColor: const Color(0xFF25D366),
            child: const Icon(Icons.chat, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: const Color(0xFFDCF8C6),
        backgroundColor: const Color(0xFFF0F2F5),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF075E54) : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}

// -----------------------------------------------------------------
// Placeholder Screen for Unimplemented Tabs
// -----------------------------------------------------------------
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Screen Coming Soon',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}