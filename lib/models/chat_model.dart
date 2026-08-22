class ChatModel {
  final String id; // receiverId
  final String? chatRoomId;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isGroup;
  final bool isPinned;
  final bool isFavorite;
  final bool isUnread;
  final int unreadCount;
  final bool hasStory;

  ChatModel({
    required this.id,
    this.chatRoomId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    this.isGroup = false,
    this.isPinned = false,
    this.isFavorite = false,
    this.isUnread = false,
    this.unreadCount = 0,
    this.hasStory = false,
  });
}