import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';
import 'search_screen.dart';

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _filterController = TextEditingController();

  bool _isSearching = false;
  String _filterQuery = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _openChatWithUser(UserModel user, {bool isSelf = false}) {
    final String displayName = isSelf ? '${user.name.isNotEmpty ? user.name : 'Message yourself'} (You)' : user.name;
    final chat = ChatModel(
      id: user.uid,
      name: displayName,
      lastMessage: 'Tap to chat',
      time: '',
      avatarUrl: user.profileImage.isNotEmpty
          ? user.profileImage
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chat: chat,
          receiverId: user.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final selfName = currentUser?.displayName ?? 'You';

    return StreamBuilder<List<UserModel>>(
      stream: _databaseService.getContactsStream(_currentUserId),
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? [];
        final filteredContacts = _filterQuery.isEmpty
            ? contacts
            : contacts
                .where((c) =>
                    c.name.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                    c.email.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                    c.uniqueId.toLowerCase().contains(_filterQuery.toLowerCase()))
                .toList();

        final int totalCount = contacts.length;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: _isSearching
                ? TextField(
                    controller: _filterController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search contacts...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    onChanged: (val) {
                      setState(() => _filterQuery = val.trim());
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$totalCount contact${totalCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _filterQuery = '';
                      _filterController.clear();
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (val) {
                  if (val == 'add') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  } else if (val == 'refresh') {
                    setState(() {});
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'add', child: Text('Add new contact')),
                  const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                  const PopupMenuItem(value: 'help', child: Text('Help')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (!_isSearching) ...[
                // Action 1: New group
                _buildActionTile(
                  icon: Icons.group_add,
                  title: 'New group',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                    );
                  },
                ),

                // Action 2: New contact (Opens search & add contact page)
                _buildActionTile(
                  icon: Icons.person_add_alt_1,
                  title: 'New contact',
                  trailing: IconButton(
                    icon: const Icon(Icons.qr_code_2_outlined, color: Colors.black54, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                ),

                // Action 3: New community
                _buildActionTile(
                  icon: Icons.groups_outlined,
                  title: 'New community',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Communities feature coming soon!')),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Section Header: Contacts on App
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Contacts on App',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Self-Chat: "Message yourself"
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0078FF).withValues(alpha: 0.15),
                    child: Text(
                      selfName.isNotEmpty ? selfName[0].toUpperCase() : 'Y',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF0078FF),
                      ),
                    ),
                  ),
                  title: Text(
                    '$selfName (You)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  subtitle: Text(
                    'Message yourself',
                    style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                  ),
                  onTap: () {
                    final selfUser = UserModel(
                      uid: _currentUserId,
                      uniqueId: '',
                      name: selfName,
                      email: currentUser?.email ?? '',
                      lastSeen: null,
                      createdAt: DateTime.now(),
                    );
                    _openChatWithUser(selfUser, isSelf: true);
                  },
                ),
              ],

              // Contact items (Only users added/connected with)
              if (filteredContacts.isEmpty && contacts.isEmpty && !_isSearching)
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    children: [
                      Icon(Icons.person_search_outlined, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No added contacts yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap "New contact" above to search by Chat ID, Name, or Email and add your friends!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0078FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Add New Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else if (filteredContacts.isEmpty && _isSearching)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No matching contacts found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14.5),
                    ),
                  ),
                )
              else
                ...filteredContacts.map((contact) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: contact.profileImage.isNotEmpty ? NetworkImage(contact.profileImage) : null,
                      onBackgroundImageError: contact.profileImage.isNotEmpty ? (_, _) {} : null,
                      child: contact.profileImage.isEmpty
                          ? Text(
                              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF0078FF),
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      contact.about.isNotEmpty ? contact.about : 'Hey there! I am using WhatsApp.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _openChatWithUser(contact),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF0078FF),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      trailing: trailing,
    );
  }
}
