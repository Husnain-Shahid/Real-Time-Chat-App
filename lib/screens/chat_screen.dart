import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'chat_details_screen.dart';
import 'active_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // Dummy messages matching your screenshot layout
  final List<MessageModel> _messages = [
    MessageModel(
      text: 'Chal ma v karda aj msg',
      time: '9:23 PM',
      isMe: false,
    ),
    MessageModel(
      text: 'Nala manu report dekhai zara',
      time: '9:23 PM',
      isMe: false,
    ),
    MessageModel(
      text: 'Nala manu report dekhai zara',
      time: '9:24 PM',
      isMe: true,
      replyTo: 'Nala manu report dekhai zara',
      replyAuthor: 'Ahmad Hassan',
    ),
    MessageModel(
      text: 'Okay',
      time: '9:24 PM',
      isMe: true,
    ),
    MessageModel(
      text: 'Ma send krda wa',
      time: '9:25 PM',
      isMe: true,
    ),
    MessageModel(
      text: 'Okay',
      time: '9:25 PM',
      isMe: false,
    ),
    MessageModel(
      text: 'lo boss',
      time: '9:25 PM',
      isMe: true,
    ),
    MessageModel(
      text: 'Chal sai a vekhda far subha ma v send karda ga',
      time: '9:26 PM',
      isMe: false,
    ),
    MessageModel(
      text: 'Hala msg karda sir nu',
      time: '9:26 PM',
      isMe: false,
    ),
    MessageModel(
      text: 'Week_06_Report_(SP24-BSE-014).docx',
      time: '9:28 PM',
      isMe: true,
      fileName: 'Week_06_Report_(SP24-BSE-014).docx',
    ),
    MessageModel(
      text: 'Good ho gia',
      time: '9:28 PM',
      isMe: false,
    ),
    MessageModel(
      text: 'Hala msg karda sir nu',
      time: '9:28 PM',
      isMe: true,
      replyTo: 'Hala msg karda sir nu',
      replyAuthor: 'Ahmad Hassan',
    ),
    MessageModel(
      text: 'Suba kr lavi',
      time: '9:28 PM',
      isMe: true,
      reaction: '👍',
    ),
    MessageModel(
      text: 'Good ho gia',
      time: '9:28 PM',
      isMe: true,
      replyTo: 'Good ho gia',
      replyAuthor: 'Ahmad Hassan',
    ),
    MessageModel(
      text: 'G',
      time: '9:28 PM',
      isMe: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DE), // WhatsApp chat background color tint
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        leadingWidth: 70,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            GestureDetector(
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(widget.chat.avatarUrl),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatDetailsScreen(
                      contactName: 'Hussnain Ac',
                      phoneNumber: '+92 340 3912622',
                    ),
                  ),
                );
              }
            ),
          ],
        ),
        title: GestureDetector(
          child: Text(
            widget.chat.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatDetailsScreen(
                  contactName: 'Hussnain Ac',
                  phoneNumber: '+92 340 3912622',
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActiveCallScreen(
                  contactName: 'Hi Husnain',
                ),
              ),
            );
          }),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view_contact', child: Text('View contact')),
              const PopupMenuItem(value: 'media', child: Text('Media, links, and docs')),
              const PopupMenuItem(value: 'search', child: Text('Search')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview box if available
            if (message.replyTo != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(
                      color: isMe ? const Color(0xFF075E54) : Colors.blue,
                      width: 4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.replyAuthor ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isMe ? const Color(0xFF075E54) : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.replyTo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            // File attachment check
            if (message.fileName != null) ...[
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.grey, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.fileName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Message content & time layout using Wrap to prevent any overlapping or overflow
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8.0, // space between text and timestamp when inline
              runSpacing: 2.0, // vertical space if timestamp wraps to next line
              children: [
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.done_all, size: 14, color: Colors.blue),
                    ],
                  ],
                ),
              ],
            ),

            // Reaction Badge overlay if available
            if (message.reaction != null)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(message.reaction!, style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.attach_file, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF075E54),
            child: IconButton(
              icon: const Icon(Icons.mic, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}