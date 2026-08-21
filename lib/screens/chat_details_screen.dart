import 'package:flutter/material.dart';

class ChatDetailsScreen extends StatelessWidget {
  final String contactName;
  final String phoneNumber;

  const ChatDetailsScreen({
    super.key,
    this.contactName = 'Hussnain Ac',
    this.phoneNumber = '+92 340 3912622',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Elegant Collapsing Header
          SliverAppBar(
            expandedHeight: 310.0,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F5744)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFF38BDF8),
                          child: Text(
                            contactName.isNotEmpty ? contactName[0] : 'H',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        contactName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Quick Action Buttons Row
                  _buildCardContainer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionChip(icon: Icons.call_rounded, label: 'Audio', onTap: () {}),
                        _buildActionChip(icon: Icons.videocam_rounded, label: 'Video', onTap: () {}),
                        _buildActionChip(icon: Icons.search_rounded, label: 'Search', onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Media, Links & Docs Card
                  _buildCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: const Text(
                            'Media, links, and docs',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('52', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                          onTap: () {},
                        ),
                        SizedBox(
                          height: 95,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                            children: [
                              _buildMediaThumbnail('https://images.unsplash.com/photo-1579546929518-9e396f3cc809'),
                              _buildMediaThumbnail('https://images.unsplash.com/photo-1557683316-973673baf926'),
                              _buildMediaThumbnail('https://images.unsplash.com/photo-1507525428034-b723cf961d3e'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Storage & Privacy Settings Group
                  _buildCardContainer(
                    child: Column(
                      children: [
                        _buildSettingTile(icon: Icons.folder_open_rounded, title: 'Manage storage', subtitle: '140.6 MB', onTap: () {}),
                        _buildSettingTile(icon: Icons.notifications_active_outlined, title: 'Notifications', subtitle: 'Default', onTap: () {}),
                        _buildSettingTile(icon: Icons.photo_library_outlined, title: 'Media visibility', subtitle: 'Default (Yes)', onTap: () {}),
                        _buildSettingTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Encryption',
                          subtitle: 'Messages and calls are end-to-end encrypted.',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Groups in Common Section
                  _buildCardContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '6 Groups in common',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGroupItem(
                          icon: Icons.group_add_rounded,
                          color: const Color(0xFF0F5744),
                          title: 'Create group with $contactName',
                          onTap: () {},
                        ),
                        _buildGroupItem(
                          icon: Icons.person_add_alt_1_rounded,
                          color: const Color(0xFF0F5744),
                          title: 'Add to groups',
                          subtitle: "Add this contact to groups you're in",
                          onTap: () {},
                        ),
                        _buildGroupItem(
                          avatarText: 'T',
                          color: const Color(0xFF2563EB),
                          title: 'Techaxe Official',
                          subtitle: 'Anas, $contactName, MUTAHIR, Techaxe...',
                          onTap: () {},
                        ),
                        _buildGroupItem(
                          avatarText: 'IS',
                          color: const Color(0xFF0D9488),
                          title: 'Internship Spring 2026',
                          subtitle: '+92 300 1516184, +92 306 0227529...',
                          onTap: () {},
                        ),
                        _buildGroupItem(
                          avatarText: 'CS',
                          color: const Color(0xFFEA580C),
                          title: 'COMSATS Skills Development',
                          subtitle: 'Rana Raffay, +92 309 8714265...',
                          onTap: () {},
                        ),
                        _buildGroupItem(
                          avatarText: 'BF',
                          color: const Color(0xFFDB2777),
                          title: 'Best Friends Forever🥰🥰',
                          subtitle: '$contactName, +92 306 6920207...',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Favorite / List Actions Card
                  _buildCardContainer(
                    child: Column(
                      children: [
                        _buildSettingTile(icon: Icons.favorite_border_rounded, title: 'Add to Favorites', onTap: () {}),
                        _buildSettingTile(icon: Icons.list_alt_rounded, title: 'Add to list', onTap: () {}),
                      ],
                    ),
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

  // Safe Material Card Wrapper that provides the Material ancestor to fix ListTile errors
  Widget _buildCardContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF0F5744), size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F5744),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      onTap: onTap,
    );
  }

  Widget _buildGroupItem({IconData? icon, String? avatarText, required Color color, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(0.15),
        child: icon != null
            ? Icon(icon, color: color, size: 20)
            : Text(avatarText!, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      onTap: onTap,
    );
  }
}