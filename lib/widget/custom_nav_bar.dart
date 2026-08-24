import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 2, 14, bottomPadding > 0 ? 2 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Glassmorphic Segmented Capsule: Chats, Updates, Calls
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCapsuleItem(
                            context,
                            index: 0,
                            icon: Icons.chat_bubble_outline,
                            activeIcon: Icons.chat_bubble,
                            label: 'Chats',
                            badgeCount: unreadChats,
                          ),
                        ),
                        Expanded(
                          child: _buildCapsuleItem(
                            context,
                            index: 1,
                            icon: Icons.update_outlined,
                            activeIcon: Icons.update,
                            label: 'Updates',
                          ),
                        ),
                        Expanded(
                          child: _buildCapsuleItem(
                            context,
                            index: 2,
                            icon: Icons.call_outlined,
                            activeIcon: Icons.call,
                            label: 'Calls',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Glassmorphic Separate Floating Profile Circle Button
            _buildSeparateProfileButton(
              context,
              index: 3,
              userId: currentUserId,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCapsuleItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    const activeBlue = Color(0xFF0078FF);
    final activeBackground = const Color(0xFFE5F1FF).withValues(alpha: 0.92);

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0078FF).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? activeBlue : Colors.black87,
                    size: 21,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: -9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0078FF),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? activeBlue : Colors.black87,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeparateProfileButton(
    BuildContext context, {
    required int index,
    required String? userId,
  }) {
    final isSelected = currentIndex == index;
    const activeBlue = Color(0xFF0078FF);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 60,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? activeBlue.withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.72),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.8),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? activeBlue.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isSelected ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
              ),
              child: ClipOval(
                child: userId == null
                    ? CircleAvatar(
                        backgroundColor: isSelected ? activeBlue : const Color(0xFFE5F1FF),
                        child: Icon(
                          Icons.person,
                          size: 22,
                          color: isSelected ? Colors.white : activeBlue,
                        ),
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
                              backgroundColor: const Color(0xFFE5F1FF),
                              backgroundImage: CachedNetworkImageProvider(profileImage),
                              onBackgroundImageError: (_, _) {},
                            );
                          }

                          return CircleAvatar(
                            backgroundColor: isSelected ? activeBlue : const Color(0xFFE5F1FF),
                            child: Icon(
                              Icons.person,
                              size: 22,
                              color: isSelected ? Colors.white : activeBlue,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}