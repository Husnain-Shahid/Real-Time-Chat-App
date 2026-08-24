import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _readReceipts = true;
  bool _conversationTones = true;
  bool _highPriorityNotifications = true;
  String _selectedTheme = 'System default';
  String _selectedLanguage = 'English (device\'s language)';

  @override
  bool get wantKeepAlive => true;

  void _showQrCodeModal(Map<String, dynamic> userData) {
    final String name = userData['name'] ?? 'User';
    final String uniqueId = userData['uniqueId'] ?? '';
    final String profileImage = userData['profileImage'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'QR Code',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F1FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0078FF).withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFE5F1FF),
                        backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                        child: profileImage.isEmpty
                            ? const Icon(Icons.person, size: 40, color: Color(0xFF0078FF))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Messenger Contact',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      // QR Code representation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2, size: 180, color: Color(0xFF0078FF)),
                            const SizedBox(height: 8),
                            Text(
                              uniqueId,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Color(0xFF0078FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.copy, color: Color(0xFF0078FF), size: 18),
                        label: const Text('Copy ID', style: TextStyle(color: Color(0xFF0078FF))),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: uniqueId));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat ID copied')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0078FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                        label: const Text('Share Code', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sharing Chat ID: $uniqueId')),
                          );
                        },
                      ),
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

  void _showAccountSheet() {
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _buildSheetItem(icon: Icons.security, title: 'Security notifications', subtitle: 'Show security notifications on this device'),
              _buildSheetItem(icon: Icons.key, title: 'Passkeys', subtitle: 'Create a passkey for secure login'),
              _buildSheetItem(icon: Icons.email_outlined, title: 'Email address', subtitle: currentUser?.email ?? 'Not set'),
              _buildSheetItem(icon: Icons.phone_android, title: 'Change number', subtitle: 'Migrate account info, groups & settings'),
              _buildSheetItem(
                icon: Icons.delete_forever,
                title: 'Delete account',
                subtitle: 'Permanently delete your account and data',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteAccount();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text('Privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  _buildSheetItem(icon: Icons.visibility, title: 'Last seen and online', subtitle: 'Everyone'),
                  _buildSheetItem(icon: Icons.account_circle_outlined, title: 'Profile photo', subtitle: 'Everyone'),
                  _buildSheetItem(icon: Icons.info_outline, title: 'About', subtitle: 'Everyone'),
                  _buildSheetItem(icon: Icons.donut_large, title: 'Status', subtitle: 'My contacts'),
                  SwitchListTile(
                    secondary: const Icon(Icons.done_all, color: Colors.grey),
                    title: const Text('Read receipts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('If turned off, you won\'t send or receive Read receipts', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _readReceipts,
                    activeThumbColor: const Color(0xFF0078FF),
                    onChanged: (val) {
                      setModalState(() => _readReceipts = val);
                      setState(() => _readReceipts = val);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSheetItem(icon: Icons.timer_outlined, title: 'Disappearing messages', subtitle: 'Off'),
                  _buildSheetItem(icon: Icons.block, title: 'Blocked contacts', subtitle: 'None'),
                  _buildSheetItem(icon: Icons.fingerprint, title: 'App lock', subtitle: 'Disabled'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChatsSheet() {
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Chats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _buildSheetItem(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                subtitle: _selectedTheme,
                onTap: () {
                  Navigator.pop(ctx);
                  _showThemeDialog();
                },
              ),
              _buildSheetItem(icon: Icons.wallpaper, title: 'Wallpaper', subtitle: 'Default wallpaper'),
              _buildSheetItem(icon: Icons.cloud_upload_outlined, title: 'Chat backup', subtitle: 'Back up to Google Drive'),
              _buildSheetItem(
                icon: Icons.history,
                title: 'Chat history',
                subtitle: 'Export, clear, or delete all chats',
                onTap: () {
                  Navigator.pop(ctx);
                  _showChatHistoryOptions();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Choose theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['System default', 'Light', 'Dark'].map((theme) {
              return ListTile(
                title: Text(theme),
                leading: Icon(
                  _selectedTheme == theme ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _selectedTheme == theme ? const Color(0xFF0078FF) : Colors.grey,
                ),
                onTap: () {
                  setState(() => _selectedTheme = theme);
                  Navigator.pop(dCtx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('App language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              'English (device\'s language)',
              'Urdu',
              'Arabic',
              'Spanish',
              'French',
              'German',
            ].map((lang) {
              return ListTile(
                title: Text(lang),
                leading: Icon(
                  _selectedLanguage == lang ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _selectedLanguage == lang ? const Color(0xFF0078FF) : Colors.grey,
                ),
                onTap: () {
                  setState(() => _selectedLanguage = lang);
                  Navigator.pop(dCtx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showChatHistoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chat history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Color(0xFFD32F2F)),
                title: const Text('Clear all chats', style: TextStyle(color: Color(0xFFD32F2F))),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All chat messages cleared')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Color(0xFFD32F2F)),
                title: const Text('Delete all chats', style: TextStyle(color: Color(0xFFD32F2F))),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All chats deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined, color: Colors.grey),
                    title: const Text('Conversation tones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Play sounds for incoming and outgoing messages', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _conversationTones,
                    activeThumbColor: const Color(0xFF0078FF),
                    onChanged: (val) {
                      setModalState(() => _conversationTones = val);
                      setState(() => _conversationTones = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: Colors.grey),
                    title: const Text('High priority notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Show previews of notifications at top of the screen', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _highPriorityNotifications,
                    activeThumbColor: const Color(0xFF0078FF),
                    onChanged: (val) {
                      setModalState(() => _highPriorityNotifications = val);
                      setState(() => _highPriorityNotifications = val);
                    },
                  ),
                  _buildSheetItem(icon: Icons.music_note, title: 'Notification tone', subtitle: 'Default (Spaceline)'),
                  _buildSheetItem(icon: Icons.vibration, title: 'Vibrate', subtitle: 'Default'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpSheet() {
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Help', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _buildSheetItem(icon: Icons.help_center_outlined, title: 'Help Center', subtitle: 'Get help, contact us, privacy policy'),
              _buildSheetItem(icon: Icons.contact_support_outlined, title: 'Contact us', subtitle: 'Questions? Need help?'),
              _buildSheetItem(icon: Icons.description_outlined, title: 'Terms and Privacy Policy', subtitle: 'Read our legal policies'),
              _buildSheetItem(
                icon: Icons.info_outline,
                title: 'App info',
                subtitle: 'Chattrix Version 2.26.1',
                onTap: () {
                  Navigator.pop(ctx);
                  showAboutDialog(
                    context: context,
                    applicationName: 'Chattrix',
                    applicationVersion: '2.26.1',
                    applicationIcon: const Icon(Icons.chat, color: Color(0xFF0078FF), size: 40),
                    children: const [
                      Text('A complete real-time messaging application built with Flutter, Firebase, and Cloudinary.'),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? const Color(0xFFD32F2F) : Colors.grey[700], size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFD32F2F) : Colors.black87,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
      onTap: onTap ?? () {},
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete this account?'),
          content: const Text('Deleting your account will erase your message history, delete you from all WhatsApp groups, and remove your backups.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dCtx);
                try {
                  final uid = currentUser?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                    await currentUser?.delete();
                  }
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting account: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogOut() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log out of WhatsApp?'),
          content: const Text('Are you sure you want to log out from this account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0078FF)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = userData['name'] ?? 'User';
          final String bio = userData['about'] ?? userData['bio'] ?? 'Hey there! I am using Chattrix App.';
          final String profileImage = userData['profileImage'] ?? '';
          final String uniqueId = userData['uniqueId'] ?? '';

          return CustomScrollView(
            slivers: [
              // Signature Collapsing SliverAppBar with Clean White Background & Floating Bubble Elements
              SliverAppBar(
                backgroundColor: Colors.white,
                expandedHeight: 250.0,
                pinned: true,
                elevation: 0,
                title: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_2, color: Colors.black87, size: 26),
                    onPressed: () => _showQrCodeModal(userData),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userData: userData),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(color: const Color(0xFFF2F7FD)),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 35,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 15,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    bio,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                CustomPaint(
                                  size: const Size(12, 6),
                                  painter: _TrianglePainter(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color(0xFFE5F1FF),
                                    backgroundImage: profileImage.isNotEmpty
                                        ? NetworkImage(profileImage)
                                        : null,
                                    onBackgroundImageError: profileImage.isNotEmpty ? (_, _) {} : null,
                                    child: profileImage.isEmpty
                                        ? const Icon(Icons.person, size: 50, color: Color(0xFF0078FF))
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Name, Chat ID and Complete Settings List
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(userData: userData),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: uniqueId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat ID copied to clipboard')),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chat ID: $uniqueId',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF0078FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 14, color: Color(0xFF0078FF)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),

                      // Settings Items List with Full Polish & Working BottomSheets
                      _buildSettingItem(
                        icon: Icons.key_outlined,
                        title: 'Account',
                        subtitle: 'Security notifications, change number',
                        onTap: _showAccountSheet,
                      ),
                      _buildSettingItem(
                        icon: Icons.lock_outline,
                        title: 'Privacy',
                        subtitle: 'Block contacts, disappearing messages',
                        onTap: _showPrivacySheet,
                      ),
                      _buildSettingItem(
                        icon: Icons.chat_bubble_outline,
                        title: 'Chats',
                        subtitle: 'Theme, wallpapers, chat history',
                        onTap: _showChatsSheet,
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Message, group & call tones',
                        onTap: _showNotificationsSheet,
                      ),
                      _buildSettingItem(
                        icon: Icons.data_usage_outlined,
                        title: 'Storage and data',
                        subtitle: 'Network usage, auto-download',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Storage & data options')),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.language,
                        title: 'App language',
                        subtitle: _selectedLanguage,
                        onTap: _showLanguageDialog,
                      ),
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Help',
                        subtitle: 'Help center, contact us, privacy policy',
                        onTap: _showHelpSheet,
                      ),
                      _buildSettingItem(
                        icon: Icons.group_add_outlined,
                        title: 'Invite a friend',
                        subtitle: 'Share Chattrix with friends and family',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: 'Join me on Chattrix Chat! Use my Chat ID: $uniqueId'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite text copied to clipboard!')),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.logout,
                        title: 'Log Out',
                        subtitle: 'Sign out from your account',
                        isDestructive: true,
                        onTap: _confirmLogOut,
                      ),

                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          'from\nChattrix',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? const Color(0xFFD32F2F) : Colors.grey[600], size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFD32F2F) : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          : null,
      onTap: onTap ?? () {},
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}