import 'package:flutter/material.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  // Dummy status model and list
  final List<Map<String, dynamic>> _statuses = [
    {
      'name': 'Tahreem',
      'imageUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      'hasStory': true,
    },
    {
      'name': 'Sir Shafique ...',
      'imageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      'hasStory': true,
    },
    {
      'name': 'Rizwan Army',
      'imageUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      'hasStory': true,
    },
    {
      'name': 'Ahmad Hassan',
      'imageUrl': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce',
      'hasStory': true,
    },
  ];

  // Dummy channels list
  final List<Map<String, dynamic>> _channels = [
    {
      'name': 'CNN News18',
      'time': '7:59 AM',
      'message': 'Cargo Ship Carrying Turkish...',
      'unreadCount': 118,
      'isLink': true,
      'avatarColor': Colors.red,
    },
    {
      'name': 'Cool Education (Career Guide)',
      'time': '7:51 AM',
      'message': 'عمران خان کو الشفاء ہاسپٹل سے صبح سویر...',
      'unreadCount': 3,
      'isLink': false,
      'avatarColor': Colors.green,
    },
    {
      'name': 'BBC News US',
      'time': '5:46 AM',
      'message': 'Prime Minister Mark Carney ha...',
      'unreadCount': 121,
      'isLink': false,
      'avatarColor': Colors.red[900],
    },
    {
      'name': 'Dawn.com',
      'time': '1:30 AM',
      'message': 'PTI founder Imran Khan was shifted...',
      'unreadCount': 0,
      'isLink': false,
      'avatarColor': Colors.black,
    },
    {
      'name': 'ScholarshipsAds - Scholars...',
      'time': 'Yesterday',
      'message': 'https://www.findinguni.com/sc...',
      'unreadCount': 105,
      'isLink': true,
      'avatarColor': Colors.blue[900],
    },
    {
      'name': 'Geo News',
      'time': 'Yesterday',
      'message': 'Federal Cabinet Approved Amendment...',
      'unreadCount': 12,
      'isLink': false,
      'avatarColor': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Updates',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'status_privacy', child: Text('Status privacy')),
              const PopupMenuItem(value: 'create_channel', child: Text('Create channel')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // Status Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

          // Horizontal Scrollable Status List
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _statuses.length + 1, // +1 for "Add status" item
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStatusCard();
                }
                final status = _statuses[index - 1];
                return _buildStatusCard(status['name'], status['imageUrl']);
              },
            ),
          ),

          const Divider(thickness: 8, color: Color(0xFFF0F2F5)),

          // Channels Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Channels',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Explore', style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Channels List
          ..._channels.map((channel) => ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: channel['avatarColor'],
              child: Text(
                channel['name'][0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            title: Text(
              channel['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  if (channel['isLink']) ...[
                    const Icon(Icons.link, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      channel['message'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  channel['time'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                if (channel['unreadCount'] > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${channel['unreadCount']}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {},
          )),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'pencil_update',
            mini: true,
            backgroundColor: const Color(0xFFF0F2F5),
            elevation: 2,
            onPressed: () {},
            child: const Icon(Icons.edit, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'camera_update',
            backgroundColor: const Color(0xFF25D366),
            child: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // "Add Status" custom vertical story card widget
  Widget _buildAddStatusCard() {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Add status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Standard user status card widget with gradient border effect
  Widget _buildStatusCard(String name, String imageUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF25D366), width: 3),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(imageUrl),
              ),
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}