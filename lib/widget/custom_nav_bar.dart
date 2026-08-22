import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/home_provider.dart';

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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final homeProvider = Provider.of<HomeProvider>(context);
    final unreadChats = homeProvider.totalUnreadChatsCount;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding > 0 ? bottomPadding + 4 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            badgeCount: unreadChats,
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
            badgeCount: 1,
          ),
          _buildProfileNavItem(
            context,
            index: 4,
            label: 'You',
            userId: currentUserId,
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
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    const activeColor = Color(0xFF075E54);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              if (badgeCount > 0)
                Positioned(
                  top: 2,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
    required String? userId,
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
            child: userId == null
                ? const CircleAvatar(
                    radius: 13,
                    backgroundColor: Color(0xFFC7E8FA),
                    child: Icon(Icons.person, size: 16, color: Color(0xFF008069)),
                  )
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                    builder: (context, snapshot) {
                      String profileImage = '';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        profileImage = data?['profileImage'] ?? '';
                      }
                      if (profileImage.isEmpty) {
                        profileImage = FirebaseAuth.instance.currentUser?.photoURL ?? '';
                      }

                      if (profileImage.isNotEmpty) {
                        return CircleAvatar(
                          radius: 13,
                          backgroundColor: const Color(0xFFC7E8FA),
                          backgroundImage: NetworkImage(profileImage),
                          onBackgroundImageError: (_, _) {},
                        );
                      }

                      return const CircleAvatar(
                        radius: 13,
                        backgroundColor: Color(0xFFC7E8FA),
                        child: Icon(Icons.person, size: 16, color: Color(0xFF008069)),
                      );
                    },
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