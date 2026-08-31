import 'package:flutter/material.dart';
import '../models/message_model.dart';

/// Reusable ChatBubble widget displaying sent/received messages with delivery status,
/// timestamps, reply previews, and interactive selection.
class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? receiverName;

  const ChatBubble({
    super.key,
    required this.message,
    this.isMe = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.receiverName,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isSelected ? const Color(0xFF0078FF).withValues(alpha: 0.15) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF0078FF) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.replyTo != null && message.replyTo!.isNotEmpty)
                      _buildReplyPreview(),
                    _buildMessageText(),
                    const SizedBox(height: 2),
                    _buildMessageFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isMe ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : const Color(0xFF0078FF),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyAuthor != null && message.replyAuthor!.isNotEmpty)
            Text(
              message.replyAuthor!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : const Color(0xFF0078FF),
              ),
            ),
          Text(
            message.replyTo ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText() {
    return Text(
      message.text,
      style: TextStyle(
        fontSize: 15,
        color: isMe ? Colors.white : const Color(0xFF1E293B),
        height: 1.3,
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          message.time,
          style: TextStyle(
            fontSize: 11,
            color: isMe ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF94A3B8),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (message.isRead) {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Color(0xFF38BDF8), // Light Blue seen tick
        key: Key('chat_bubble_status_seen'),
      );
    } else {
      return Icon(
        Icons.done,
        size: 15,
        color: Colors.white.withValues(alpha: 0.75),
        key: const Key('chat_bubble_status_sent'),
      );
    }
  }
}
