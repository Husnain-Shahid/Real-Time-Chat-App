import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/cloudinary_service.dart';
import '../services/database_service.dart';
import '../services/image_picker_service.dart';
import 'chat_screen.dart';

class CreateGroupInfoScreen extends StatefulWidget {
  final List<UserModel> selectedMembers;

  const CreateGroupInfoScreen({
    super.key,
    required this.selectedMembers,
  });

  @override
  State<CreateGroupInfoScreen> createState() => _CreateGroupInfoScreenState();
}

class _CreateGroupInfoScreenState extends State<CreateGroupInfoScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final ImagePickerService _pickerService = ImagePickerService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Uint8List? _groupImageBytes;
  String? _groupImageFileName;
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.pinkAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    final xFile = await _pickerService.pickImageXFile(source: ImageSource.camera);
                    if (xFile != null) {
                      final bytes = await xFile.readAsBytes();
                      setState(() {
                        _groupImageBytes = bytes;
                        _groupImageFileName = xFile.name;
                      });
                    }
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purpleAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    final xFile = await _pickerService.pickImageXFile(source: ImageSource.gallery);
                    if (xFile != null) {
                      final bytes = await xFile.readAsBytes();
                      setState(() {
                        _groupImageBytes = bytes;
                        _groupImageFileName = xFile.name;
                      });
                    }
                  },
                ),
                if (_groupImageBytes != null)
                  _buildSourceOption(
                    icon: Icons.delete_outline,
                    label: 'Remove',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _groupImageBytes = null;
                        _groupImageFileName = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a group subject / name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      String? groupImageUrl;

      // Upload group image to Cloudinary if selected
      if (_groupImageBytes != null) {
        final uploadResult = await _cloudinaryService.uploadImage(
          imageBytes: _groupImageBytes!,
          fileName: _groupImageFileName ?? 'group_${DateTime.now().millisecondsSinceEpoch}.png',
          onProgress: (_) {},
        );
        if (uploadResult != null) {
          groupImageUrl = uploadResult['secure_url'];
        }
      }

      final memberUids = widget.selectedMembers.map((m) => m.uid).toList();
      final chatRoomId = await _databaseService.createGroupChat(
        groupName: groupName,
        groupImage: groupImageUrl,
        memberUids: memberUids,
      );

      if (mounted) {
        final chat = ChatModel(
          id: chatRoomId,
          chatRoomId: chatRoomId,
          name: groupName,
          lastMessage: 'Tap to chat',
          time: '',
          avatarUrl: groupImageUrl ?? '',
          isGroup: true,
        );

        // Pop creation screens back to home, then open group chat
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: chat,
              receiverId: chatRoomId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserName = currentUser?.displayName ?? 'You';

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 1),
            Text(
              'Add subject',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Group Avatar & Name Input Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _groupImageBytes != null ? MemoryImage(_groupImageBytes!) : null,
                      child: _groupImageBytes == null
                          ? const Icon(Icons.camera_alt, color: Colors.black45, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _groupNameController,
                      maxLength: 25,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Type group subject here...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 15.5),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0078FF), width: 2),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black26),
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text(
                'Provide a group subject and optional group icon',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),
              const Divider(),

              // Participants Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Participants: ${widget.selectedMembers.length + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Colors.grey[700],
                  ),
                ),
              ),

              // Participants Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Self preview
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF0078FF).withValues(alpha: 0.15),
                        child: Text(
                          currentUserName.isNotEmpty ? currentUserName[0].toUpperCase() : 'Y',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0078FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 65,
                        child: Text(
                          '$currentUserName (You)',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),

                  // Selected members preview
                  ...widget.selectedMembers.map((member) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: member.profileImage.isNotEmpty
                              ? CachedNetworkImageProvider(member.profileImage)
                              : null,
                          onBackgroundImageError: member.profileImage.isNotEmpty ? (_, _) {} : null,
                          child: member.profileImage.isEmpty
                              ? Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0078FF),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 65,
                          child: Text(
                            member.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),

          if (_isCreating)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0078FF)),
                    SizedBox(height: 16),
                    Text(
                      'Creating group...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isCreating
          ? null
          : FloatingActionButton(
              heroTag: 'create_group_confirm_fab',
              backgroundColor: const Color(0xFF0078FF),
              elevation: 4,
              onPressed: _createGroup,
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
    );
  }
}
