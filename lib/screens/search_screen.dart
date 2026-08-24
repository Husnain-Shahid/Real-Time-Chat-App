import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  
  List<UserModel> _searchResults = [];
  final Set<String> _addedContactUids = {};
  bool _isLoading = false;
  bool _hasSearched = false;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadExistingContacts();
  }

  Future<void> _loadExistingContacts() async {
    if (currentUser == null) return;
    try {
      final contacts = await _databaseService.getContactsStream(currentUser!.uid).first;
      if (mounted) {
        setState(() {
          _addedContactUids.addAll(contacts.map((c) => c.uid));
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts in search: $e');
    }
  }

  void _searchUsers() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      final results = await _databaseService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAddContact(UserModel user) async {
    final uid = user.uid;
    final isAlready = _addedContactUids.contains(uid);

    setState(() {
      if (isAlready) {
        _addedContactUids.remove(uid);
      } else {
        _addedContactUids.add(uid);
      }
    });

    try {
      if (isAlready) {
        await _databaseService.removeContact(uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} removed from contacts')),
          );
        }
      } else {
        await _databaseService.addContact(uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} added to your contacts!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling contact: $e');
    }
  }

  void _startChat(UserModel user) async {
    final chat = ChatModel(
      id: user.uid,
      name: user.name,
      lastMessage: 'Tap to chat',
      time: '',
      avatarUrl: user.profileImage.isNotEmpty
          ? user.profileImage
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
    );

    // Also automatically ensure they are added to contacts for convenience
    if (!_addedContactUids.contains(user.uid)) {
      await _databaseService.addContact(user.uid);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chat: chat,
            receiverId: user.uid,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Contact',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black87),
        ),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Input Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _searchUsers(),
                            decoration: const InputDecoration(
                              hintText: 'Search Chat ID, Email, or Name',
                              hintStyle: TextStyle(color: Colors.black38, fontSize: 14.5),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _hasSearched = false;
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.black45, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0078FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _searchUsers,
                  child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0078FF)),
                  )
                : _searchResults.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isContact = _addedContactUids.contains(user.uid);

                          return RepaintBoundary(
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 1.5,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                     CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFF0078FF).withValues(alpha: 0.12),
                                      backgroundImage: user.profileImage.isNotEmpty
                                          ? CachedNetworkImageProvider(user.profileImage)
                                          : null,
                                      onBackgroundImageError: user.profileImage.isNotEmpty ? (_, _) {} : null,
                                      child: user.profileImage.isEmpty
                                          ? Text(
                                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                color: Color(0xFF0078FF),
                                              ),
                                            )
                                          : null,
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111B21),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.uniqueId.isNotEmpty ? 'ID: ${user.uniqueId}' : user.email,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF0078FF),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (user.about.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            user.about,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      // Add Contact Toggle Button
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isContact ? const Color(0xFF0078FF) : Colors.black87,
                                          side: BorderSide(
                                            color: isContact ? const Color(0xFF0078FF) : Colors.grey.shade400,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        onPressed: () => _toggleAddContact(user),
                                        icon: Icon(
                                          isContact ? Icons.check : Icons.person_add_alt_1,
                                          size: 16,
                                          color: isContact ? const Color(0xFF0078FF) : Colors.black87,
                                        ),
                                        label: Text(
                                          isContact ? 'Added' : 'Add',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isContact ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Direct Message Button
                                      GestureDetector(
                                        onTap: () => _startChat(user),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0078FF),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.chat, size: 14, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text(
                                                'Chat',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          );
                        },
                      )
                    : _hasSearched
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_outlined, size: 56, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No user found',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Make sure the Chat ID (e.g. U8xK-29mP), Email, or Name is correct.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13.5),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.contact_mail_outlined, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Search to add new contacts',
                                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter a friend\'s Chat ID, Name, or Email above to connect and start chatting.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}