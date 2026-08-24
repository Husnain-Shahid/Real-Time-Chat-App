import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ActiveCallScreen extends StatefulWidget {
  final String contactName;
  final String? profileImageUrl;

  const ActiveCallScreen({
    super.key,
    this.contactName = 'Hi Husnain',
    this.profileImageUrl,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  bool isSpeakerOn = false;
  bool isMuted = false;
  bool isVideoOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21), // Dark WhatsApp Call Background
      body: SafeArea(
        child: Stack(
          children: [
            // Top Section: Header & Encrypted Label & Profile Avatar
            Column(
              children: [
                const SizedBox(height: 12),
                // Top Action Icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Contact Name
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // End-to-end encrypted badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock, color: Colors.white54, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'End-to-end encrypted',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Centered Profile Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundColor: const Color(0xFF222D34),
                    backgroundImage: widget.profileImageUrl != null
                        ? CachedNetworkImageProvider(widget.profileImageUrl!)
                        : null,
                    child: widget.profileImageUrl == null
                        ? const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white70,
                    )
                        : null,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),

            // Bottom Control Sheet
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First Row of Controls (Speaker, Video, Mute)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCallButton(
                          icon: isSpeakerOn ? Icons.volume_up : Icons.volume_mute,
                          label: 'Speaker',
                          isActive: isSpeakerOn,
                          onTap: () => setState(() => isSpeakerOn = !isSpeakerOn),
                        ),
                        _buildCallButton(
                          icon: isVideoOn ? Icons.videocam : Icons.videocam_off,
                          label: 'Video',
                          isActive: isVideoOn,
                          onTap: () => setState(() => isVideoOn = !isVideoOn),
                        ),
                        _buildCallButton(
                          icon: isMuted ? Icons.mic_off : Icons.mic,
                          label: 'Mute',
                          isActive: isMuted,
                          onTap: () => setState(() => isMuted = !isMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Second Row of Controls (More, Share, End Call)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCallButton(
                          icon: Icons.more_horiz,
                          label: 'More',
                          onTap: () {},
                        ),
                        _buildCallButton(
                          icon: Icons.screen_share,
                          label: 'Share',
                          onTap: () {},
                        ),
                        // Red End Call Button
                        _buildCallButton(
                          icon: Icons.call_end,
                          label: 'End',
                          backgroundColor: const Color(0xFFEF4444),
                          iconColor: Colors.white,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Call Button Widget
  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor ??
                  (isActive ? Colors.white : const Color(0xFF2A3942)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? (isActive ? Colors.black : Colors.white),
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}