import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Safely retrieve bottom system gesture inset to avoid overlapping
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      // Added extra vertical padding + bottom safe area inset
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding > 0 ? bottomPadding + 4 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chats',
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.update_outlined,
            activeIcon: Icons.update,
            label: 'Updates',
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.group_outlined,
            activeIcon: Icons.group,
            label: 'Communities',
          ),
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.call_outlined,
            activeIcon: Icons.call,
            label: 'Calls',
          ),
          _buildProfileNavItem(
            context,
            index: 4,
            label: 'You',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required int index,
        required IconData icon,
        required IconData activeIcon,
        required String label,
      }) {
    final isSelected = currentIndex == index;
    const activeColor = Color(0xFF075E54);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD8F3DC) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black87 : Colors.black54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNavItem(
      BuildContext context, {
        required int index,
        required String label,
        required String avatarUrl,
      }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD8F3DC) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircleAvatar(
              radius: 13,
              backgroundImage: NetworkImage(avatarUrl),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black87 : Colors.black54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}