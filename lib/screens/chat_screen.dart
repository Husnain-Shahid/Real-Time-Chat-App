import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../provider/chat_provider.dart';
import '../provider/media_provider.dart';
import 'chat_details_screen.dart';
import 'group_details_screen.dart';
import 'add_group_members_screen.dart';
import 'active_call_screen.dart';

class ChatScreen extends StatelessWidget {
  final ChatModel chat;
  final String receiverId;
  final bool isEmbedded;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.receiverId,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize the chat stream once when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).initChat(receiverId);
    });

    return _ChatScreenContent(
      chat: chat,
      receiverId: receiverId,
      isEmbedded: isEmbedded,
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final ChatModel chat;
  final String receiverId;
  final bool isEmbedded;

  const _ChatScreenContent({
    required this.chat,
    required this.receiverId,
    this.isEmbedded = false,
  });

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  int _newMessagesWhileScrolledCount = 0;
  int _lastKnownMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false).setActiveChat(widget.receiverId);
      }
    });

    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String chatRoomId = widget.receiverId.startsWith('group_')
        ? widget.receiverId
        : _databaseService.getChatRoomId(currentUserId, widget.receiverId);
    NotificationService.instance.setActiveChatRoomId(chatRoomId);

    // Mark messages as read immediately upon opening
    _databaseService.markMessagesAsRead(widget.receiverId);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final show = (max - _scrollController.offset) > 250;
      if (show != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = show;
          if (!show) _newMessagesWhileScrolledCount = 0;
        });
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String chatRoomId = widget.receiverId.startsWith('group_')
        ? widget.receiverId
        : _databaseService.getChatRoomId(currentUserId, widget.receiverId);

    if (state == AppLifecycleState.resumed) {
      Provider.of<ChatProvider>(context, listen: false).setActiveChat(widget.receiverId);
      NotificationService.instance.setActiveChatRoomId(chatRoomId);
      _databaseService.markMessagesAsRead(widget.receiverId);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Provider.of<ChatProvider>(context, listen: false).setActiveChat(null);
      NotificationService.instance.clearActiveChatRoomId();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Clear active chat status when leaving this chat screen
    Provider.of<ChatProvider>(context, listen: false).setActiveChat(null);
    NotificationService.instance.clearActiveChatRoomId();
    _databaseService.markMessagesAsRead(widget.receiverId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final isSelecting = chatProvider.isSelectingMessages;
        final selectedMsgs = chatProvider.getSelectedMessages(widget.receiverId);

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) return;
            FocusScope.of(context).unfocus();
            chatProvider.setActiveChat(null);
            chatProvider.clearReply();
            chatProvider.clearMessageSelection();
            mediaProvider.clearMedia();
            _databaseService.markMessagesAsRead(widget.receiverId);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFEFE7DE),
            appBar: isSelecting
                ? AppBar(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => chatProvider.clearMessageSelection(),
                    ),
                    title: Text(
                      '${chatProvider.selectedCount}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    actions: [
                      if (selectedMsgs.length == 1)
                        IconButton(
                          tooltip: 'Reply',
                          icon: const Icon(Icons.reply, color: Colors.black87),
                          onPressed: () {
                            chatProvider.setReplyMessage(selectedMsgs.first);
                            chatProvider.clearMessageSelection();
                          },
                        ),
                      if (selectedMsgs.any((m) => m.text.isNotEmpty && !m.hasMedia))
                        IconButton(
                          tooltip: 'Copy',
                          icon: const Icon(Icons.copy, color: Colors.black87),
                          onPressed: () {
                            final texts = selectedMsgs.map((m) => m.text).where((t) => t.isNotEmpty).join('\n');
                            Clipboard.setData(ClipboardData(text: texts));
                            chatProvider.clearMessageSelection();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message copied')),
                            );
                          },
                        ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEA0038)),
                        onPressed: () => _showDeleteMessagesDialog(context, chatProvider),
                      ),
                    ],
                  )
                : AppBar(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0.5,
                    automaticallyImplyLeading: !widget.isEmbedded,
                    leading: widget.isEmbedded
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
                            onPressed: () => Navigator.pop(context),
                          ),
                    titleSpacing: widget.isEmbedded ? 16 : 0,
                    title: GestureDetector(
                      onTap: () {
                        if (widget.chat.isGroup) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailsScreen(
                                chatRoomId: widget.receiverId,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailsScreen(
                                receiverId: widget.receiverId,
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: const Color(0xFFE5F1FF),
                            backgroundImage: widget.chat.avatarUrl.isNotEmpty ? CachedNetworkImageProvider(widget.chat.avatarUrl) : null,
                            onBackgroundImageError: widget.chat.avatarUrl.isNotEmpty ? (_, _) {} : null,
                            child: widget.chat.avatarUrl.isEmpty
                                ? (widget.chat.isGroup
                                    ? const Icon(Icons.groups, size: 22, color: Color(0xFF0078FF))
                                    : Text(
                                        widget.chat.name.isNotEmpty ? widget.chat.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0078FF)),
                                      ))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.chat.name,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                widget.chat.isGroup
                                    ? Text(
                                        'Tap here for group info',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.normal,
                                        ),
                                      )
                                    : const Text(
                                        'online',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0078FF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.videocam_outlined, color: Colors.black87, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_outlined, color: Colors.black87, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActiveCallScreen(
                                contactName: widget.chat.name,
                                profileImageUrl: widget.chat.avatarUrl.isNotEmpty ? widget.chat.avatarUrl : null,
                              ),
                            ),
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black87),
                        onSelected: (value) {
                          if (value == 'clear_chat') {
                            _showClearChatConfirmationDialog(context, chatProvider);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view_contact', child: Text('View contact')),
                          const PopupMenuItem(value: 'media', child: Text('Media, links, and docs')),
                          const PopupMenuItem(value: 'search', child: Text('Search')),
                          const PopupMenuItem(value: 'wallpaper', child: Text('Wallpaper')),
                          const PopupMenuItem(
                            value: 'clear_chat',
                            child: Text('Clear chat', style: TextStyle(color: Color(0xFFEA0038))),
                          ),
                        ],
                      ),
                    ],
                  ),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_background_2.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final messages = chatProvider.getMessages(widget.receiverId);

                        if (messages.isEmpty) {
                          return ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                            children: [
                              _ChatTopHeaderCard(
                                chat: widget.chat,
                                receiverId: widget.receiverId,
                              ),
                            ],
                          );
                        }

                        // Automatically mark any incoming unread messages as read in real time
                        final hasUnreadIncoming = messages.any((m) => !m.isMe && !m.isRead);
                        if (hasUnreadIncoming) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _databaseService.markMessagesAsRead(widget.receiverId);
                          });
                        }

                        // Track new incoming messages while user is scrolled up
                        if (messages.length > _lastKnownMessageCount) {
                          if (_showScrollToBottom && _lastKnownMessageCount > 0) {
                            final diff = messages.length - _lastKnownMessageCount;
                            _newMessagesWhileScrolledCount += diff;
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom(animate: _lastKnownMessageCount > 0);
                            });
                          }
                          _lastKnownMessageCount = messages.length;
                        }

                        return Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              itemCount: messages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _ChatTopHeaderCard(
                                    chat: widget.chat,
                                    receiverId: widget.receiverId,
                                  );
                                }

                                final messageIndex = index - 1;
                                final message = messages[messageIndex];
                                final previousMessage = messageIndex > 0 ? messages[messageIndex - 1] : null;

                                final bool showDateDivider = previousMessage == null ||
                                    isDifferentDay(previousMessage.timestamp, message.timestamp);

                                final isMsgSelected = chatProvider.isMessageSelected(message.id);

                                final bubble = _MessageBubble(
                                  key: ValueKey(message.id),
                                  message: message,
                                  receiverName: widget.chat.name,
                                  receiverAvatarUrl: widget.chat.avatarUrl,
                                  isGroup: widget.chat.isGroup,
                                  isSelected: isMsgSelected,
                                  onTap: () {
                                    if (isSelecting) {
                                      chatProvider.toggleMessageSelection(message.id);
                                    }
                                  },
                                  onLongPress: () {
                                    chatProvider.toggleMessageSelection(message.id);
                                  },
                                );

                                if (showDateDivider) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _ChatDateDivider(text: formatChatDateDivider(message.timestamp)),
                                      bubble,
                                    ],
                                  );
                                }

                                return bubble;
                              },
                            ),
                            if (_showScrollToBottom)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    _scrollToBottom(animate: true);
                                    setState(() {
                                      _newMessagesWhileScrolledCount = 0;
                                    });
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0078FF), size: 28),
                                        if (_newMessagesWhileScrolledCount > 0)
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0078FF),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '$_newMessagesWhileScrolledCount',
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
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

            // Media Selection Preview
            Consumer<MediaProvider>(
              builder: (context, mediaProv, child) {
                if (mediaProv.selectedFile == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: mediaProv.isVideo
                                ? Container(
                                    width: 60, height: 60,
                                    color: Colors.black12,
                                    child: const Icon(Icons.videocam, size: 30, color: Colors.deepOrange),
                                  )
                                : (mediaProv.selectedBytes != null
                                    ? Image.memory(
                                        mediaProv.selectedBytes!,
                                        width: 60, height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : (mediaProv.selectedFile != null && !kIsWeb
                                        ? Image.file(
                                            mediaProv.selectedFile!,
                                            width: 60, height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.image, size: 40))),
                          ),
                          Positioned(
                            right: 0, top: 0,
                            child: InkWell(
                              onTap: () => mediaProv.clearMedia(),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaProv.isVideo ? 'Video Selected' : 'Image Selected',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (mediaProv.isUploading) ...[
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: mediaProv.uploadProgress,
                                color: const Color(0xFF0078FF),
                                backgroundColor: Colors.grey[200],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Reply Preview Area
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final replyingTo = provider.replyingToMessage;
                if (replyingTo == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Container(width: 4, height: 35, color: const Color(0xFF0078FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyingTo.isMe ? 'You' : widget.chat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF0078FF),
                              ),
                            ),
                            Text(
                              replyingTo.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => provider.clearReply(),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildMessageInputArea(context, chatProvider, mediaProvider),
          ],
        ),
      ),
    ),
  );
},
);
  }

  Future<void> _showVoiceRecorderSheet(
    BuildContext context,
    ChatProvider chatProvider,
    MediaProvider mediaProvider,
  ) async {
    final started = await mediaProvider.startVoiceRecording();
    if (!started || !context.mounted) {
      if (mediaProvider.errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mediaProvider.errorMessage!)),
        );
        mediaProvider.clearError();
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WhatsAppVoiceRecordingSheet(
          receiverId: widget.receiverId,
          receiverName: widget.chat.name,
          caption: chatProvider.textController.text.trim(),
          onSent: () => chatProvider.textController.clear(),
        );
      },
    );

    if (mediaProvider.isVoiceRecording) {
      await mediaProvider.cancelVoiceRecording();
    }
    await mediaProvider.clearRecordedVoice();
  }

  void _showAttachmentSheet(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WhatsAppAttachmentSheet(
          onPickGallery: () async {
            Navigator.pop(sheetContext);
            await mediaProvider.pickImageGallery();
          },
          onPickCamera: () async {
            Navigator.pop(sheetContext);
            await mediaProvider.pickImageCamera();
          },
          onPickVideo: () async {
            Navigator.pop(sheetContext);
            await mediaProvider.pickVideoGallery();
          },
          onPickDocument: () async {
            Navigator.pop(sheetContext);
            await mediaProvider.pickImageGallery();
          },
          onPickLocation: () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location sharing ready')),
            );
          },
          onPickContact: () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact selection ready')),
            );
          },
          onPickPoll: () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Poll creator ready')),
            );
          },
          onPickAiImages: () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI Image generator ready')),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInputArea(BuildContext context, ChatProvider chatProvider, MediaProvider mediaProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10, left: 4),
                    child: Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 24),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: chatProvider.textController,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      scrollPhysics: const BouncingScrollPhysics(),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey, size: 22),
                      onPressed: () => _showAttachmentSheet(context),
                    ),
                  ),
                  if (chatProvider.textController.text.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 22),
                        onPressed: () => mediaProvider.pickImageCamera(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFF0078FF),
              child: Consumer<MediaProvider>(
                builder: (context, mediaProv, child) {
                  if (mediaProv.isUploading || mediaProv.isUploadingVoice) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    );
                  }

                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: chatProvider.textController,
                    builder: (context, value, _) {
                      final hasTypedText = value.text.trim().isNotEmpty;
                      final hasSelectedMedia = mediaProv.selectedFile != null;
                      final showSendButton = hasTypedText || hasSelectedMedia;

                      return IconButton(
                        icon: Icon(
                          showSendButton ? Icons.send : Icons.mic,
                          color: Colors.white,
                          size: 21,
                        ),
                        onPressed: () async {
                          if (showSendButton) {
                            if (mediaProv.selectedFile != null) {
                              final caption = chatProvider.textController.text;
                              await mediaProv.sendMediaMessage(
                                widget.receiverId,
                                widget.chat.name,
                                caption,
                              );
                              chatProvider.textController.clear();
                              if (mediaProv.errorMessage != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(mediaProv.errorMessage!)),
                                );
                                mediaProv.clearError();
                              }
                            } else {
                              await chatProvider.sendMessage(widget.receiverId, widget.chat.name);
                            }
                            return;
                          }

                          await _showVoiceRecorderSheet(context, chatProvider, mediaProv);
                          if (mediaProv.errorMessage != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(mediaProv.errorMessage!)),
                            );
                            mediaProv.clearError();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteMessagesDialog(BuildContext context, ChatProvider chatProvider) {
    final selected = chatProvider.getSelectedMessages(widget.receiverId);
    if (selected.isEmpty) return;

    final bool allMine = selected.every((m) => m.isMe);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          selected.length == 1 ? 'Delete message?' : 'Delete ${selected.length} messages?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          allMine
              ? 'You can delete message(s) for everyone or only for yourself.'
              : 'You can delete this message for yourself.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          if (allMine)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await chatProvider.deleteSelectedMessagesForEveryone(widget.receiverId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message deleted for everyone')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete message.')),
                    );
                  }
                }
              },
              child: const Text(
                'Delete for everyone',
                style: TextStyle(color: Color(0xFFEA0038), fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await chatProvider.deleteSelectedMessagesForMe(widget.receiverId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message deleted for me')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete message.')),
                  );
                }
              }
            },
            child: const Text(
              'Delete for me',
              style: TextStyle(color: Color(0xFF0078FF), fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmationDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear chat with ${widget.chat.name}?'),
        content: const Text(
          'All messages, photos, videos, and media in this chat will be deleted. The conversation will remain in your chat list.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await chatProvider.clearChat(widget.receiverId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat with ${widget.chat.name} cleared')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to clear chat. Please try again.')),
                  );
                }
              }
            },
            child: const Text(
              'Clear chat',
              style: TextStyle(color: Color(0xFFEA0038), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getSenderColor(String name) {
  final colors = [
    const Color(0xFF1F7A8C),
    const Color(0xFFE07A5F),
    const Color(0xFF3D5A80),
    const Color(0xFFD08C00),
    const Color(0xFF6A4C93),
    const Color(0xFF1B998B),
    const Color(0xFFC3423F),
    const Color(0xFF2E86AB),
  ];
  if (name.isEmpty) return const Color(0xFF0078FF);
  final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
  return colors[hash % colors.length];
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String receiverName;
  final String receiverAvatarUrl;
  final bool isGroup;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.receiverName,
    required this.receiverAvatarUrl,
    this.isGroup = false,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: isSelected ? const Color(0xFF0078FF).withValues(alpha: 0.15) : Colors.transparent,
        child: _buildBubbleContent(context),
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    if (message.isSystemMessage) {
      return _SystemAnnouncementBubble(text: message.text);
    }

    if (message.isVoice) {
      return _VoiceNoteMessageBubble(
        key: ValueKey('voice_${message.id}'),
        message: message,
        receiverAvatarUrl: receiverAvatarUrl,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    final bool isMe = message.isMe;
    final bool isCallLog = message.text.contains('Video call') ||
        message.text.contains('Voice call') ||
        message.text.contains('Missed voice call');

    if (message.hasMedia) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isMe)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: const Icon(Icons.reply, size: 16, color: Colors.black87),
                    ),
                  ),
                if (isGroup && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: _getSenderColor(message.senderName ?? '').withValues(alpha: 0.18),
                      backgroundImage: (message.senderImage != null && message.senderImage!.isNotEmpty)
                          ? CachedNetworkImageProvider(message.senderImage!)
                          : null,
                      onBackgroundImageError: (message.senderImage != null && message.senderImage!.isNotEmpty) ? (_, _) {} : null,
                      child: (message.senderImage == null || message.senderImage!.isEmpty)
                          ? Text(
                              (message.senderName != null && message.senderName!.isNotEmpty)
                                  ? message.senderName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getSenderColor(message.senderName ?? ''),
                              ),
                            )
                          : null,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(3),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFE7F3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGroup && !isMe && message.senderName != null && message.senderName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
                          child: Text(
                            message.senderName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _getSenderColor(message.senderName!),
                            ),
                          ),
                        ),
                      if (message.replyTo != null && !message.isDeletedForEveryone)
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: _ReplyBubble(
                            author: message.replyAuthor ?? '',
                            text: message.replyTo!,
                            isMe: isMe,
                          ),
                        ),
                      _MediaContent(message: message),
                      if (message.text.trim().isNotEmpty &&
                          message.text != '📷 Photo' &&
                          message.text != '🎥 Video') ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                          child: Text(
                            message.text,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMe && !isGroup)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: const Icon(Icons.reply, size: 16, color: Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isGroup && !isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _getSenderColor(message.senderName ?? '').withValues(alpha: 0.18),
                  backgroundImage: (message.senderImage != null && message.senderImage!.isNotEmpty)
                      ? CachedNetworkImageProvider(message.senderImage!)
                      : null,
                  onBackgroundImageError: (message.senderImage != null && message.senderImage!.isNotEmpty) ? (_, _) {} : null,
                  child: (message.senderImage == null || message.senderImage!.isEmpty)
                      ? Text(
                          (message.senderName != null && message.senderName!.isNotEmpty)
                              ? message.senderName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _getSenderColor(message.senderName ?? ''),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(9, 6, 9, 5),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFE7F3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGroup && !isMe && message.senderName != null && message.senderName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Text(
                            message.senderName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _getSenderColor(message.senderName!),
                            ),
                          ),
                        ),
                      if (message.replyTo != null && !message.isDeletedForEveryone)
                        _ReplyBubble(
                          author: message.replyAuthor ?? '',
                          text: message.replyTo!,
                          isMe: isMe,
                        ),
              if (isCallLog) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        message.text.contains('Video call')
                            ? Icons.videocam_outlined
                            : (message.text.contains('Missed') ? Icons.call_missed : Icons.call_outlined),
                        size: 20,
                        color: message.text.contains('Missed') ? Colors.red : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        Text(
                          message.time,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (message.isDeletedForEveryone) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, size: 15, color: Colors.grey),
                    const SizedBox(width: 5),
                    const Text(
                      'This message was deleted',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message.time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ] else ...[
                // Inline text and timestamp wrapping layout
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.done_all,
                              size: 15,
                              color: message.isRead ? const Color(0xFF0078FF) : Colors.grey[500],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  ),
),
),
);
  }
}

class _ReplyBubble extends StatelessWidget {
  final String author;
  final String text;
  final bool isMe;

  const _ReplyBubble({
    required this.author,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAuthorMe = author == 'You' || author.toLowerCase() == 'you';
    final Color barColor = isAuthorMe ? const Color(0xFF0078FF) : const Color(0xFF7C3AED);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            color: barColor,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            author,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: barColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _MediaContent extends StatelessWidget {
  final MessageModel message;

  const _MediaContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isMe;

    if (message.isVideo) {
      return GestureDetector(
        onTap: () => _openMediaViewer(context),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            _VideoMessagePreview(key: ValueKey('video_${message.id}'), videoUrl: message.mediaUrl!),
            // Bottom duration and timestamp overlay
            Positioned(
              left: 8,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 14, color: Colors.white),
                    SizedBox(width: 3),
                    Text('0:04', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: message.isRead ? const Color(0xFF0078FF) : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _openMediaViewer(context),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                memCacheWidth: 440,
                placeholder: (context, url) => Container(
                  width: 220,
                  height: 220,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0078FF))),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 220,
                  height: 220,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            // Bottom Gradient Overlay for Timestamp & Ticks
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: message.isRead ? const Color(0xFF0078FF) : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _openMediaViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MediaViewerScreen(
          mediaUrl: message.mediaUrl!,
          mediaType: message.mediaType ?? (message.isVideo ? 'video' : 'image'),
          caption: message.text,
        ),
      ),
    );
  }
}

class _VoiceNoteMessageBubble extends StatefulWidget {
  final MessageModel message;
  final String receiverAvatarUrl;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  const _VoiceNoteMessageBubble({
    super.key,
    required this.message,
    required this.receiverAvatarUrl,
    this.onTap,
    required this.onLongPress,
  });

  @override
  State<_VoiceNoteMessageBubble> createState() => _VoiceNoteMessageBubbleState();
}

class _VoiceNoteMessageBubbleState extends State<_VoiceNoteMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.message.mediaUrl != null && widget.message.mediaUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(widget.message.mediaUrl!);
        _audioPlayer.positionStream.listen((p) {
          if (mounted) setState(() => _position = p);
        });
        _audioPlayer.durationStream.listen((d) {
          if (mounted && d != null) setState(() => _duration = d);
        });
        _audioPlayer.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing && state.processingState != ProcessingState.completed;
              if (state.processingState == ProcessingState.completed) {
                _position = Duration.zero;
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Voice note audio error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration value) {
    final safeDuration = value.isNegative ? Duration.zero : value;
    final minutes = safeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.message.isMe;
    final totalDuration = _duration > Duration.zero
        ? _duration
        : Duration(seconds: widget.message.voiceDuration?.toInt() ?? 0);
    final progress = totalDuration.inMilliseconds > 0
        ? (_position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final String myAvatarUrl = FirebaseAuth.instance.currentUser?.photoURL ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb';
    final String avatarUrl = isMe
        ? myAvatarUrl
        : (widget.receiverAvatarUrl.isNotEmpty
            ? widget.receiverAvatarUrl
            : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb');

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.fromLTRB(8, 7, 10, 5),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
              minWidth: 225,
            ),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFE7F3FF) : Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.message.replyTo != null && !widget.message.isDeletedForEveryone)
                  _ReplyBubble(
                    author: widget.message.replyAuthor ?? '',
                    text: widget.message.replyTo!,
                    isMe: isMe,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with Mic Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFE7F3FF) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic,
                            size: 14,
                            color: Color(0xFF0078FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Play / Pause Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.grey[700],
                      size: 28,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        if (_position >= totalDuration && totalDuration > Duration.zero) {
                          _audioPlayer.seek(Duration.zero);
                        }
                        _audioPlayer.play();
                      }
                    },
                  ),
                  const SizedBox(width: 3),
                  // Waveform and Duration / Timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Waveform Track with Scrubber Dot
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (details) {
                                if (totalDuration.inMilliseconds > 0 && constraints.maxWidth > 0) {
                                  final newFraction = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                  _audioPlayer.seek(Duration(milliseconds: (totalDuration.inMilliseconds * newFraction).round()));
                                }
                              },
                              onTapDown: (details) {
                                if (totalDuration.inMilliseconds > 0 && constraints.maxWidth > 0) {
                                  final newFraction = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                  _audioPlayer.seek(Duration(milliseconds: (totalDuration.inMilliseconds * newFraction).round()));
                                }
                              },
                              child: SizedBox(
                                height: 24,
                                width: constraints.maxWidth,
                                child: CustomPaint(
                                  painter: _WhatsAppWaveformPainter(
                                    progress: progress,
                                    activeColor: const Color(0xFF0078FF),
                                    inactiveColor: Colors.grey.shade400,
                                    thumbColor: const Color(0xFF0078FF),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        // Duration (left) & Timestamp + Double ticks (right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position > Duration.zero ? _position : totalDuration),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.message.time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.done_all,
                                    size: 15,
                                    color: widget.message.isRead ? const Color(0xFF0078FF) : const Color(0xFF8696A0),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.message.text.trim().isNotEmpty &&
                  widget.message.text != '🎤 Voice message' &&
                  widget.message.text != '🎤 Voice recording') ...[
                const SizedBox(height: 6),
                Text(
                  widget.message.text,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _WhatsAppWaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  _WhatsAppWaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  static const List<double> _barHeights = [
    0.18, 0.22, 0.25, 0.32, 0.40, 0.52, 0.68, 0.85, 0.95, 0.88,
    0.72, 0.92, 0.80, 0.96, 0.85, 0.70, 0.88, 0.92, 0.78, 0.85,
    0.90, 0.76, 0.82, 0.70, 0.60, 0.68, 0.55, 0.48, 0.40, 0.30,
    0.22, 0.18, 0.16, 0.15,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final int count = _barHeights.length;
    final double totalWidth = size.width;
    final double barWidth = (totalWidth / (count * 1.8)).clamp(1.5, 3.0);
    final double spacing = (totalWidth - (count * barWidth)) / (count - 1);
    final double maxHeight = size.height;
    final double thumbX = (progress * totalWidth).clamp(0.0, totalWidth);

    for (int i = 0; i < count; i++) {
      final double x = i * (barWidth + spacing);
      final double height = (maxHeight * _barHeights[i]).clamp(3.0, maxHeight);
      final double y = (maxHeight - height) / 2;

      final bool isPlayed = (x + barWidth) <= thumbX;
      paint.color = isPlayed ? activeColor : inactiveColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }

    // Draw scrubber thumb circle
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(thumbX, maxHeight / 2),
      5.5,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WhatsAppWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.thumbColor != thumbColor;
  }
}

class _VideoMessagePreview extends StatefulWidget {
  final String videoUrl;
  const _VideoMessagePreview({super.key, required this.videoUrl});

  @override
  State<_VideoMessagePreview> createState() => _VideoMessagePreviewState();
}

class _VideoMessagePreviewState extends State<_VideoMessagePreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) { if (mounted) setState(() => _initialized = true); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return Container(width: 220, height: 220, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0078FF))));
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 220, height: 220, child: VideoPlayer(_controller))),
        const CircleAvatar(backgroundColor: Colors.black38, child: Icon(Icons.play_arrow, color: Colors.white)),
      ],
    );
  }
}

class _MediaViewerScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  const _MediaViewerScreen({required this.mediaUrl, required this.mediaType, this.caption});

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
        ..initialize().then((_) { if (mounted) { setState(() {}); _videoController?.play(); _videoController?.setLooping(true); } });
    }
  }

  @override
  void dispose() { _videoController?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(isVideo ? 'Video' : 'Photo')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: isVideo
                  ? (_videoController?.value.isInitialized == true ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)) : const CircularProgressIndicator(color: Colors.white))
                  : InteractiveViewer(child: CachedNetworkImage(imageUrl: widget.mediaUrl, placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white)), errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white))),
            ),
          ),
          if (widget.caption != null && widget.caption!.isNotEmpty && widget.caption != '📷 Photo' && widget.caption != '🎥 Video')
            Container(padding: const EdgeInsets.all(16), color: Colors.black87, width: double.infinity, child: Text(widget.caption!, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _WhatsAppVoiceRecordingSheet extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String caption;
  final VoidCallback onSent;

  const _WhatsAppVoiceRecordingSheet({
    required this.receiverId,
    required this.receiverName,
    required this.caption,
    required this.onSent,
  });

  @override
  State<_WhatsAppVoiceRecordingSheet> createState() => _WhatsAppVoiceRecordingSheetState();
}

class _WhatsAppVoiceRecordingSheetState extends State<_WhatsAppVoiceRecordingSheet> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final mediaProv = Provider.of<MediaProvider>(context, listen: false);
      if (mediaProv.isVoiceRecording && !mediaProv.isVoicePaused) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProv, child) {
        final isPaused = mediaProv.isVoicePaused;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Timer (0:02) on Left + Waveform on Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatTimer(_seconds),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    _RecordingLiveWaveform(isPaused: isPaused),
                  ],
                ),
                const SizedBox(height: 22),

                // Bottom Row: Trash (Left), Pause/Resume Pill (Center), Send Button (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Trash / Delete Button (Light red circular container)
                    GestureDetector(
                      onTap: () async {
                        await mediaProv.cancelVoiceRecording();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFECEF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFEA0038),
                          size: 24,
                        ),
                      ),
                    ),

                    // Pause / Resume Pill Button (Wide rounded grey container)
                    GestureDetector(
                      onTap: () async {
                        if (isPaused) {
                          await mediaProv.resumeVoiceRecording();
                        } else {
                          await mediaProv.pauseVoiceRecording();
                        }
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPaused ? Icons.mic : Icons.pause,
                              size: 22,
                              color: isPaused ? const Color(0xFF0078FF) : Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPaused ? 'Resume' : 'Pause',
                              style: TextStyle(
                                color: isPaused ? const Color(0xFF0078FF) : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Send Button (Messenger blue circular container)
                    GestureDetector(
                      onTap: () async {
                        if (mediaProv.isUploadingVoice) return;
                        await mediaProv.stopVoiceRecording();
                        final sent = await mediaProv.sendRecordedVoiceMessage(
                          receiverId: widget.receiverId,
                          caption: widget.caption,
                        );
                        if (sent) {
                          widget.onSent();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0078FF),
                          shape: BoxShape.circle,
                        ),
                        child: mediaProv.isUploadingVoice
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecordingLiveWaveform extends StatefulWidget {
  final bool isPaused;
  const _RecordingLiveWaveform({required this.isPaused});

  @override
  State<_RecordingLiveWaveform> createState() => _RecordingLiveWaveformState();
}

class _RecordingLiveWaveformState extends State<_RecordingLiveWaveform> {
  Timer? _waveTimer;
  final List<double> _bars = [
    3.0, 4.0, 3.0, 5.0, 4.0, 3.0, 3.0, 4.0, 5.0, 3.0,
    4.0, 6.0, 8.0, 14.0, 20.0, 16.0, 22.0, 18.0, 8.0, 4.0, 3.0
  ];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _startWaveformStream();
  }

  void _startWaveformStream() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!widget.isPaused && mounted) {
        setState(() {
          // Generate realistic voice wave height variations
          final double r = _random.nextDouble();
          double nextH;
          if (r < 0.25) {
            nextH = 3.0 + _random.nextDouble() * 4.0;
          } else if (r < 0.7) {
            nextH = 8.0 + _random.nextDouble() * 12.0;
          } else {
            nextH = 18.0 + _random.nextDouble() * 8.0;
          }

          _bars.add(nextH);
          if (_bars.length > 25) {
            _bars.removeAt(0); // Moves towards left!
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _RecordingLiveWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _waveTimer?.cancel();
      } else {
        _startWaveformStream();
      }
    }
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _bars.map((height) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3.0,
            height: height.clamp(3.0, 26.0),
            decoration: BoxDecoration(
              color: const Color(0xFF54656F),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WhatsAppAttachmentSheet extends StatelessWidget {
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickVideo;
  final VoidCallback onPickDocument;
  final VoidCallback onPickLocation;
  final VoidCallback onPickContact;
  final VoidCallback onPickPoll;
  final VoidCallback onPickAiImages;

  const _WhatsAppAttachmentSheet({
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickVideo,
    required this.onPickDocument,
    required this.onPickLocation,
    required this.onPickContact,
    required this.onPickPoll,
    required this.onPickAiImages,
  });

  static const List<String> _sampleGalleryThumbnails = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=300',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300',
    'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=300',
    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=300',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Top drag handle
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 8 Grid items (2 rows x 4 columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Row 1: Gallery, Camera, Location, Contact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttachmentItem(
                        icon: Icons.photo_library_outlined,
                        color: const Color(0xFF1E88E5), // Blue
                        label: 'Gallery',
                        onTap: onPickGallery,
                      ),
                      _buildAttachmentItem(
                        icon: Icons.camera_alt_outlined,
                        color: const Color(0xFFE91E63), // Pink
                        label: 'Camera',
                        onTap: onPickCamera,
                      ),
                      _buildAttachmentItem(
                        icon: Icons.location_on_outlined,
                        color: const Color(0xFF0078FF), // Blue
                        label: 'Location',
                        onTap: onPickLocation,
                      ),
                      _buildAttachmentItem(
                        icon: Icons.person_outline,
                        color: const Color(0xFF0288D1), // Cyan/Blue
                        label: 'Contact',
                        onTap: onPickContact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 2: Document, Poll, Event, AI images
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttachmentItem(
                        icon: Icons.insert_drive_file_outlined,
                        color: const Color(0xFF7C3AED), // Purple
                        label: 'Document',
                        onTap: onPickDocument,
                      ),
                      _buildAttachmentItem(
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFFF59E0B), // Orange
                        label: 'Poll',
                        onTap: onPickPoll,
                      ),
                      _buildAttachmentItem(
                        icon: Icons.calendar_today_outlined,
                        color: const Color(0xFFEF4444), // Red
                        label: 'Event',
                        onTap: onPickLocation, // Event action
                      ),
                      _buildAttachmentItem(
                        icon: Icons.image_search_outlined,
                        color: const Color(0xFF06B6D4), // Cyan
                        label: 'AI images',
                        onTap: onPickAiImages,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Media Grid (4-column grid matching screenshot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              height: 180,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                ),
                itemCount: _sampleGalleryThumbnails.length,
                itemBuilder: (context, index) {
                  final imgUrl = _sampleGalleryThumbnails[index];
                  return GestureDetector(
                    onTap: onPickGallery,
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(color: Colors.grey[200]),
                      placeholder: (_, _) => Container(color: Colors.grey[200]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200, width: 1.2),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 26),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF54656F),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemAnnouncementBubble extends StatelessWidget {
  final String text;

  const _SystemAnnouncementBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChatDateDivider extends StatelessWidget {
  final String text;

  const _ChatDateDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

String formatChatDateDivider(DateTime? date) {
  if (date == null) return 'Today';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(date.year, date.month, date.day);
  final difference = today.difference(messageDate).inDays;

  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Yesterday';
  } else if (difference < 7 && difference > 0) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[date.weekday - 1];
  } else {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (date.year == now.year) {
      return '${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

bool isDifferentDay(DateTime? dateA, DateTime? dateB) {
  if (dateA == null || dateB == null) return dateA != dateB;
  return dateA.year != dateB.year || dateA.month != dateB.month || dateA.day != dateB.day;
}

class _ChatTopHeaderCard extends StatelessWidget {
  final ChatModel chat;
  final String receiverId;

  const _ChatTopHeaderCard({
    required this.chat,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encryption banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7D6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock, size: 13, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3),
                    children: [
                      TextSpan(
                        text:
                            'Messages and calls are end-to-end encrypted. Only people in this chat can read, listen to, or share them. ',
                      ),
                      TextSpan(
                        text: 'Learn more',
                        style: TextStyle(color: Color(0xFF0078FF), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // If Group Chat, show Welcome Card
        if (chat.isGroup)
          _GroupWelcomeCard(chat: chat, receiverId: receiverId),
      ],
    );
  }
}

class _GroupWelcomeCard extends StatelessWidget {
  final ChatModel chat;
  final String receiverId;

  const _GroupWelcomeCard({
    required this.chat,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService().getChatRoomStream(receiverId),
      builder: (context, snapshot) {
        int memberCount = 2;
        String groupImage = chat.avatarUrl;
        List<String> memberUids = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          memberUids = List<String>.from(data['users'] ?? []);
          memberCount = memberUids.length;
          groupImage = data['groupImage'] ?? groupImage;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with camera badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFE5F1FF),
                    backgroundImage: groupImage.isNotEmpty ? CachedNetworkImageProvider(groupImage) : null,
                    onBackgroundImageError: groupImage.isNotEmpty ? (_, _) {} : null,
                    child: groupImage.isEmpty
                        ? const Icon(Icons.groups, size: 40, color: Color(0xFF0078FF))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0078FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'You created this group',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Group · $memberCount members',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.35),
                  children: [
                    TextSpan(text: 'Members can add people or invite them\nusing a link. '),
                    TextSpan(
                      text: 'Edit',
                      style: TextStyle(color: Color(0xFF0078FF), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Add members button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0078FF), size: 20),
                  label: const Text(
                    'Add members',
                    style: TextStyle(
                      color: Color(0xFF0078FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddGroupMembersScreen(
                          chatRoomId: receiverId,
                          currentMemberUids: memberUids,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Invite via link or QR code button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.link, color: Color(0xFF0078FF), size: 20),
                  label: const Text(
                    'Invite via link or QR code',
                    style: TextStyle(
                      color: Color(0xFF0078FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}