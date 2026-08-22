class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String time;
  final bool isMe;
  final bool isRead;
  final String? replyTo;
  final String? replyAuthor;
  final String? fileName;
  final String? reaction;
  final String? mediaUrl;
  final String? mediaType;
  final String? publicId;
  final String? deleteToken;
  final double? voiceDuration;
  final String? senderName;
  final String? senderImage;
  final bool isDeletedForEveryone;
  final List<String> deletedFor;
  final bool isSystem;
  final DateTime? timestamp;

  String? get imageUrl => mediaUrl;
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  bool get isVoice => mediaType == 'voice' || mediaType == 'audio';
  bool get hasMedia => (mediaUrl != null && mediaUrl!.trim().isNotEmpty && !isDeletedForEveryone);
  bool get isSystemMessage =>
      isSystem ||
      senderId == 'system' ||
      text.endsWith('were added') ||
      text.endsWith('was added') ||
      text.startsWith('You removed ') ||
      text.contains(' removed ') ||
      text.contains('created group') ||
      text.contains('created this group') ||
      text.endsWith(' left');

  MessageModel({
    required this.id,
    this.senderId = '',
    this.receiverId = '',
    this.senderName,
    this.senderImage,
    required this.text,
    required this.time,
    required this.isMe,
    this.isRead = false,
    this.isSystem = false,
    this.replyTo,
    this.replyAuthor,
    this.fileName,
    this.reaction,
    this.mediaUrl,
    this.mediaType,
    this.publicId,
    this.deleteToken,
    this.voiceDuration,
    this.isDeletedForEveryone = false,
    this.deletedFor = const [],
    this.timestamp,
  });
}