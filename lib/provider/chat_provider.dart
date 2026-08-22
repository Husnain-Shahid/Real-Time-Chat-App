import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController textController = TextEditingController();

  // Cache for messages per receiverId to provide immediate UI updates
  final Map<String, List<MessageModel>> _messagesCache = {};
  final Map<String, StreamSubscription<List<MessageModel>>> _subscriptions = {};

  MessageModel? _replyingToMessage;
  MessageModel? get replyingToMessage => _replyingToMessage;

  final Set<String> _selectedMessageIds = {};
  Set<String> get selectedMessageIds => _selectedMessageIds;
  bool get isSelectingMessages => _selectedMessageIds.isNotEmpty;
  int get selectedCount => _selectedMessageIds.length;

  List<MessageModel> getMessages(String receiverId) => _messagesCache[receiverId] ?? [];

  List<MessageModel> getSelectedMessages(String receiverId) {
    final all = getMessages(receiverId);
    return all.where((m) => _selectedMessageIds.contains(m.id)).toList();
  }

  bool isMessageSelected(String messageId) => _selectedMessageIds.contains(messageId);

  void toggleMessageSelection(String messageId) {
    if (_selectedMessageIds.contains(messageId)) {
      _selectedMessageIds.remove(messageId);
    } else {
      _selectedMessageIds.add(messageId);
    }
    notifyListeners();
  }

  void clearMessageSelection() {
    _selectedMessageIds.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedMessagesForMe(String receiverId) async {
    if (_selectedMessageIds.isEmpty) return;
    final ids = _selectedMessageIds.toList();
    clearMessageSelection();
    await _databaseService.deleteMultipleMessagesForMe(receiverId, ids);
  }

  Future<void> deleteSelectedMessagesForEveryone(String receiverId) async {
    if (_selectedMessageIds.isEmpty) return;
    final selectedMsgs = getSelectedMessages(receiverId);
    clearMessageSelection();
    await _databaseService.deleteMultipleMessagesForEveryone(receiverId, selectedMsgs);
  }

  Future<void> clearChat(String receiverId) async {
    clearMessageSelection();
    clearReply();
    await _databaseService.clearChat(receiverId);
  }

  String? _activeChatReceiverId;
  String? get activeChatReceiverId => _activeChatReceiverId;

  void setActiveChat(String? receiverId) {
    _activeChatReceiverId = receiverId;
    if (receiverId != null) {
      _databaseService.markMessagesAsRead(receiverId);
    }
  }

  void initChat(String receiverId) {
    if (_subscriptions.containsKey(receiverId)) return;

    // Start listening to the stream and update cache
    _subscriptions[receiverId] = _databaseService.getMessages(receiverId).listen((messages) {
      _messagesCache[receiverId] = messages;
      notifyListeners();

      // If this conversation is currently open on the user's screen, immediately mark incoming as read
      if (_activeChatReceiverId == receiverId) {
        final hasUnreadIncoming = messages.any((m) => !m.isMe && !m.isRead);
        if (hasUnreadIncoming) {
          _databaseService.markMessagesAsRead(receiverId);
        }
      }
    });
  }

  void setReplyMessage(MessageModel? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  void clearReply() {
    _replyingToMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String receiverId, String chatName, {bool isGroup = false}) async {
    if (textController.text.trim().isEmpty) return;

    String text = textController.text.trim();
    textController.clear();

    final currentReply = _replyingToMessage;
    clearReply();

    // The Firestore stream will automatically update the UI through the listener
    await _databaseService.sendMessage(
      receiverId: receiverId,
      text: text,
      replyTo: currentReply?.text,
      replyAuthor: currentReply?.isMe == true ? 'You' : chatName,
      isGroup: isGroup,
    );
  }

  @override
  void dispose() {
    textController.dispose();
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}