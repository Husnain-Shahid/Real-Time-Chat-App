import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

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
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Centered Profile Avatar
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 65,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A884), // WhatsApp teal/green accent
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Profile Info List Items
            _buildProfileItem(
              icon: Icons.person_outline,
              title: 'Name',
              subtitle: 'Husnain',
              onTap: () {},
            ),
            _buildProfileItem(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: '.',
              onTap: () {},
            ),
            _buildProfileItem(
              icon: Icons.alternate_email,
              title: 'Username',
              subtitle: 'Reserve username',
              isActionText: true,
              onTap: () {},
            ),
            _buildProfileItem(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: '+92 340 3912622',
              onTap: () {},
            ),
            _buildProfileItem(
              icon: Icons.link,
              title: 'Links',
              subtitle: 'Add links',
              isActionText: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Row Item matching WhatsApp's settings list design
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isActionText = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: isActionText ? const Color(0xFF00A884) : Colors.black87,
                      fontWeight: isActionText ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}