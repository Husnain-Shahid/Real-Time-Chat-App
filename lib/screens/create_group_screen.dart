import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'create_group_info_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();

  final Set<UserModel> _selectedMembers = {};
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleMember(UserModel user) {
    setState(() {
      if (_selectedMembers.any((m) => m.uid == user.uid)) {
        _selectedMembers.removeWhere((m) => m.uid == user.uid);
      } else {
        _selectedMembers.add(user);
      }
    });
  }

  void _continueToGroupInfo() {
    if (_selectedMembers.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupInfoScreen(
          selectedMembers: _selectedMembers.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _databaseService.getContactsStream(_currentUserId),
      builder: (context, snapshot) {
        final allContacts = (snapshot.data ?? [])
            .where((c) => c.uid != _currentUserId)
            .toList();

        final filteredContacts = _searchQuery.isEmpty
            ? allContacts
            : allContacts
                .where((c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.uniqueId.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        final int selectedCount = _selectedMembers.length;

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
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search contacts...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        selectedCount > 0
                            ? '$selectedCount of ${allContacts.length} selected'
                            : 'Add participants',
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
                      _searchQuery = '';
                      _searchController.clear();
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Selected Members Chips Carousel at top
              if (_selectedMembers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedMembers.map((member) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF00A884).withValues(alpha: 0.15),
                                  backgroundImage: member.profileImage.isNotEmpty
                                      ? NetworkImage(member.profileImage)
                                      : null,
                                  onBackgroundImageError: member.profileImage.isNotEmpty ? (_, _) {} : null,
                                  child: member.profileImage.isEmpty
                                      ? Text(
                                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF00A884),
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: () => _toggleMember(member),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                member.name.split(' ').first,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Contacts List
              Expanded(
                child: filteredContacts.isEmpty
                    ? Center(
                        child: Text(
                          allContacts.isEmpty
                              ? 'No contacts available to add.\nAdd contacts from the contacts page first.'
                              : 'No matching contacts found',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14.5),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final user = filteredContacts[index];
                          final isSelected = _selectedMembers.any((m) => m.uid == user.uid);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            onTap: () => _toggleMember(user),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: user.profileImage.isNotEmpty
                                      ? NetworkImage(user.profileImage)
                                      : null,
                                  onBackgroundImageError: user.profileImage.isNotEmpty ? (_, _) {} : null,
                                  child: user.profileImage.isEmpty
                                      ? Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF00A884),
                                          ),
                                        )
                                      : null,
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A884),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              user.about.isNotEmpty ? user.about : 'Hey there! I am using WhatsApp.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF00A884), size: 24)
                                : Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 24),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: _selectedMembers.isNotEmpty
              ? FloatingActionButton(
                  heroTag: 'create_group_next_fab',
                  backgroundColor: const Color(0xFF00A884),
                  elevation: 4,
                  onPressed: _continueToGroupInfo,
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 26),
                )
              : null,
        );
      },
    );
  }
}
