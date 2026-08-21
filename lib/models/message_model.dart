class MessageModel {
  final String text;
  final String time;
  final bool isMe;
  final bool isRead;
  final String? replyTo;
  final String? replyAuthor;
  final String? fileName;
  final String? reaction;

  MessageModel({
    required this.text,
    required this.time,
    required this.isMe,
    this.isRead = true,
    this.replyTo,
    this.replyAuthor,
    this.fileName,
    this.reaction,
  });
}