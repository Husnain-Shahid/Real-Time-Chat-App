import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart';
import '../services/image_picker_service.dart';
import 'crop_image_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePickerService _pickerService = ImagePickerService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _phoneController;

  String _profileImage = '';
  String _uniqueId = '';
  String _email = '';
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;
  bool _isSaving = false;

  final List<String> _aboutPresets = [
    'Available',
    'Busy',
    'At school',
    'At the movies',
    'At work',
    'Battery about to die',
    'Can\'t talk, WhatsApp only',
    'In a meeting',
    'At the gym',
    'Sleeping',
    'Urgent calls only',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _aboutController = TextEditingController(
      text: widget.userData['about'] ?? widget.userData['bio'] ?? 'Hey there! I am using WhatsApp.',
    );
    _phoneController = TextEditingController(text: widget.userData['phoneNumber'] ?? '+92 300 1234567');
    _profileImage = widget.userData['profileImage'] ?? '';
    _uniqueId = widget.userData['uniqueId'] ?? '';
    _email = widget.userData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(bool fromCamera) async {
    final XFile? pickedFile = await _pickerService.pickImageXFile(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile == null) return;

    final Uint8List imageBytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    // Open CropImageScreen so user can zoom, rotate, crop before upload
    final dynamic croppedResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropImageScreen(imageBytes: imageBytes),
      ),
    );

    if (croppedResult == null) return;
    final Uint8List finalBytes = croppedResult is Uint8List
        ? croppedResult
        : (croppedResult is File ? await croppedResult.readAsBytes() : imageBytes);

    setState(() {
      _isUploadingPhoto = true;
      _uploadProgress = 0.05;
    });

    try {
      final uploadRes = await _cloudinaryService.uploadImage(
        imageBytes: finalBytes,
        fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.png',
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      final String? newUrl = uploadRes?['secure_url'];
      if (newUrl != null && newUrl.isNotEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'profileImage': newUrl,
          });
          await FirebaseAuth.instance.currentUser?.updatePhotoURL(newUrl);
        }

        if (mounted) {
          setState(() {
            _profileImage = newUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModalOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: const Color(0xFF0078FF),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUploadPhoto(true);
                      },
                    ),
                    _buildModalOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: const Color(0xFF0078FF),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUploadPhoto(false);
                      },
                    ),
                    if (_profileImage.isNotEmpty)
                      _buildModalOption(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        color: Colors.red,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'profileImage': '',
                            });
                          }
                          setState(() => _profileImage = '');
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDialog({
    required String title,
    required TextEditingController controller,
    required String fieldKey,
    int maxLength = 30,
  }) {
    final tempController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: tempController,
            autofocus: true,
            maxLength: maxLength,
            decoration: InputDecoration(
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0078FF), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0078FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final text = tempController.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogCtx);
                setState(() {
                  controller.text = text;
                });
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    fieldKey: text,
                  });
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutPresetsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select About status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF0078FF)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditDialog(
                          title: 'Enter About',
                          controller: _aboutController,
                          fieldKey: 'about',
                          maxLength: 139,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ..._aboutPresets.map((preset) {
                final isSelected = _aboutController.text == preset;
                return ListTile(
                  title: Text(
                    preset,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0078FF) : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF0078FF))
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _aboutController.text = preset;
                    });
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                        'about': preset,
                        'bio': preset,
                      });
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAllChanges() async {
    final String newName = _nameController.text.trim();
    final String newAbout = _aboutController.text.trim();
    final String newPhone = _phoneController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': newName,
          'about': newAbout,
          'bio': newAbout,
          'phoneNumber': newPhone,
        });
        await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAllChanges,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0078FF)))
                : const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF0078FF), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Picture with Camera Action Button
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: const Color(0xFFE5F1FF),
                    backgroundImage: _profileImage.isNotEmpty ? CachedNetworkImageProvider(_profileImage) : null,
                    onBackgroundImageError: _profileImage.isNotEmpty ? (_, _) {} : null,
                    child: _profileImage.isEmpty
                        ? const Icon(Icons.person, size: 80, color: Color(0xFF0078FF))
                        : null,
                  ),
                  if (_isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            color: const Color(0xFF0078FF),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0078FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Name Field
            _buildProfileTile(
              icon: Icons.person_outline,
              title: 'Name',
              subtitle: _nameController.text,
              infoNote: 'This is not your username or PIN. This name will be visible to your WhatsApp contacts.',
              onTap: () => _openEditDialog(
                title: 'Enter your name',
                controller: _nameController,
                fieldKey: 'name',
                maxLength: 25,
              ),
            ),
            const Divider(height: 1, indent: 70),

            // About Field
            _buildProfileTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: _aboutController.text,
              onTap: _showAboutPresetsSheet,
            ),
            const Divider(height: 1, indent: 70),

            // Phone Field
            _buildProfileTile(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: _phoneController.text,
              onTap: () => _openEditDialog(
                title: 'Enter phone number',
                controller: _phoneController,
                fieldKey: 'phoneNumber',
                maxLength: 20,
              ),
            ),
            const Divider(height: 1, indent: 70),

            // Chat ID / Unique ID Field
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: const Icon(Icons.alternate_email, color: Color(0xFF0078FF), size: 24),
              title: const Text('Chat ID', style: TextStyle(fontSize: 13, color: Colors.grey)),
              subtitle: Text(
                _uniqueId,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFF0078FF), size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _uniqueId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat ID copied to clipboard')),
                  );
                },
              ),
            ),
            const Divider(height: 1, indent: 70),

            // Email (read-only)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: const Icon(Icons.email_outlined, color: Colors.grey, size: 24),
              title: const Text('Email', style: TextStyle(fontSize: 13, color: Colors.grey)),
              subtitle: Text(
                _email,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? infoNote,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isNotEmpty ? subtitle : 'Not set',
                    style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                  if (infoNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      infoNote,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.edit, size: 18, color: Color(0xFF0078FF)),
          ],
        ),
      ),
    );
  }
}