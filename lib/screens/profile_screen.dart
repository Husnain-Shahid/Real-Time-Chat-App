import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; // Make sure to import your new screen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Collapsing SliverAppBar with Doodle Background & Floating Elements
          SliverAppBar(
            backgroundColor: const Color(0xFFEFEAE2),
            expandedHeight: 250.0,
            pinned: true,
            elevation: 0,
            title: const Text(
              'Husnain',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black87),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black87),
                onPressed: () {},
              ),
              // Linked to EditProfileScreen
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
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
                  // Doodle background color wrapper
                  Container(color: const Color(0xFFEFEAE2)),

                  // White curved container background overlapping at the bottom
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

                  // Positioned Avatar, Plus Badge, and Status Bubble Stack
                  Positioned(
                    bottom: 15,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Bubble with Pointer Tail
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
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

                        // Avatar and Green Plus Button Stack
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
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

          // Name and Settings List Content Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // User Name and Dropdown Arrow Row (Tapping also opens Edit Profile)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Husnain',
                          style: TextStyle(
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
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),

                  // Settings Items List
                  _buildSettingItem(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Subscriptions',
                    subtitle: 'Explore premium benefits',
                  ),
                  _buildSettingItem(
                    icon: Icons.devices,
                    title: 'Linked devices',
                    subtitle: 'Use WhatsApp on other devices',
                  ),
                  _buildSettingItem(
                    icon: Icons.key_outlined,
                    title: 'Account',
                    subtitle: 'Security notifications, change number',
                  ),
                  _buildSettingItem(
                    icon: Icons.lock_outline,
                    title: 'Privacy',
                    subtitle: 'Blocked accounts, disappearing messages',
                  ),
                  _buildSettingItem(
                    icon: Icons.photo_library_outlined,
                    title: 'Lists',
                    subtitle: 'Manage people and groups',
                  ),
                  _buildSettingItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chats',
                    subtitle: 'Theme, wallpapers, chat history',
                  ),
                  _buildSettingItem(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Chat theme, app icon, app theme',
                  ),
                  _buildSettingItem(
                    icon: Icons.campaign_outlined,
                    title: 'Broadcasts',
                    subtitle: 'Manage lists and send broadcasts',
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Message, group & call tones',
                  ),
                  _buildSettingItem(
                    icon: Icons.data_usage,
                    title: 'Storage and data',
                    subtitle: 'Network usage, auto-download',
                  ),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: 'Help center',
                    subtitle: 'Help docs, contact us, privacy policy',
                  ),
                  _buildSettingItem(
                    icon: Icons.people_outline,
                    title: 'Invite a friend',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      )
          : null,
      onTap: () {},
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