import 'package:flutter/material.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy recent calls list matching your design
    final List<Map<String, dynamic>> recentCalls = [
      {
        'name': 'Abdullah Khan',
        'time': 'Yesterday, 4:56 PM',
        'avatarUrl': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce',
        'isVideo': false,
        'isIncoming': true,
        'missed': false,
      },
      {
        'name': 'Tatlim (2)',
        'time': 'Yesterday, 6:36 AM',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        'isVideo': true,
        'isIncoming': false,
        'missed': false,
      },
      {
        'name': 'Tatlim (6)',
        'time': 'August 19, 10:12 PM',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        'isVideo': true,
        'isIncoming': false,
        'missed': false,
      },
      {
        'name': 'Abdullah Khan (2)',
        'time': 'August 19, 10:15 AM',
        'avatarUrl': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce',
        'isVideo': false,
        'isIncoming': false,
        'missed': false,
      },
      {
        'name': 'Ahsan Iqbal',
        'time': 'August 18, 4:21 PM',
        'avatarUrl': null, // Fallback initial letter
        'isVideo': false,
        'isIncoming': false,
        'missed': false,
      },
      {
        'name': 'Tatlim',
        'time': 'August 18, 1:58 PM',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        'isVideo': true,
        'isIncoming': false,
        'missed': false,
      },
      {
        'name': 'Rana Zubair',
        'time': 'August 18, 7:11 AM',
        'avatarUrl': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
        'isVideo': false,
        'isIncoming': true,
        'missed': true, // Missed call indicator style
      },
      {
        'name': 'Tatlim (3)',
        'time': 'August 18, 1:01 AM',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        'isVideo': false,
        'isIncoming': true,
        'missed': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Calls',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear_log', child: Text('Clear call log')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // Top Action Buttons Row (Call, Schedule, Keypad, Favorites)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CallActionButton(icon: Icons.phone, label: 'Call'),
                _CallActionButton(icon: Icons.calendar_today_outlined, label: 'Schedule'),
                _CallActionButton(icon: Icons.dialpad, label: 'Keypad'),
                _CallActionButton(icon: Icons.favorite_border, label: 'Favorites'),
              ],
            ),
          ),

          // "Recent" Section Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Recent',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Calls List
          ...recentCalls.map((call) => ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: call['avatarUrl'] == null ? const Color(0xFF0078FF) : null,
              backgroundImage: call['avatarUrl'] != null ? NetworkImage(call['avatarUrl']) : null,
              child: call['avatarUrl'] == null
                  ? Text(
                call['name'][0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              )
                  : null,
            ),
            title: Text(
              call['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: call['missed'] ? Colors.red : Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(
                    call['isIncoming'] ? Icons.call_received : Icons.call_made,
                    size: 16,
                    color: call['missed'] ? Colors.red : const Color(0xFF0078FF),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      call['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                call['isVideo'] ? Icons.videocam : Icons.phone,
                color: const Color(0xFF0078FF),
              ),
              onPressed: () {},
            ),
            onTap: () {},
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0078FF),
        child: const Icon(Icons.add_call, color: Colors.white),
        onPressed: () {},
      ),
    );
  }
}

// Helper Widget for the Top Circular Action Buttons
class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CallActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0078FF), size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}