import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String chatRoomId;
  final List<String> currentMemberUids;

  const AddGroupMembersScreen({
    super.key,
    required this.chatRoomId,
    required this.currentMemberUids,
  });

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();

  final Set<UserModel> _selectedMembers = {};
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isAdding = false;

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

  Future<void> _confirmAddMembers() async {
    if (_selectedMembers.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      final newUids = _selectedMembers.map((m) => m.uid).toList();
      await _databaseService.addGroupMembers(
        chatRoomId: widget.chatRoomId,
        newMemberUids: newUids,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_selectedMembers.length} participant${_selectedMembers.length > 1 ? 's' : ''} to group',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding members: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _databaseService.getContactsStream(_currentUserId),
      builder: (context, snapshot) {
        final allContacts = (snapshot.data ?? [])
            .where((c) => !widget.currentMemberUids.contains(c.uid) && c.uid != _currentUserId)
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
                        'Add participants',
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
                            : '${allContacts.length} contacts available',
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
          body: Stack(
            children: [
              Column(
                children: [
                  // Selected Members Chips Carousel
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
                                      onBackgroundImageError:
                                          member.profileImage.isNotEmpty ? (_, _) {} : null,
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

                  // Available Contacts List
                  Expanded(
                    child: filteredContacts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                allContacts.isEmpty
                                    ? 'All your contacts are already members of this group!'
                                    : 'No matching contacts found',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14.5),
                              ),
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
                                      onBackgroundImageError:
                                          user.profileImage.isNotEmpty ? (_, _) {} : null,
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

              if (_isAdding)
                Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A884)),
                  ),
                ),
            ],
          ),
          floatingActionButton: _selectedMembers.isNotEmpty && !_isAdding
              ? FloatingActionButton(
                  heroTag: 'confirm_add_members_fab',
                  backgroundColor: const Color(0xFF00A884),
                  elevation: 4,
                  onPressed: _confirmAddMembers,
                  child: const Icon(Icons.check, color: Colors.white, size: 28),
                )
              : null,
        );
      },
    );
  }
}
