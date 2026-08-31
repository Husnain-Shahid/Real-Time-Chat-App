import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class HomeProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  ChatModel? _activeDetailChat;
  ChatModel? get activeDetailChat => _activeDetailChat;

  String? _activeDetailReceiverId;
  String? get activeDetailReceiverId => _activeDetailReceiverId;

  void setActiveDetailChat(ChatModel? chat, String? receiverId) {
    _activeDetailChat = chat;
    _activeDetailReceiverId = receiverId;
    notifyListeners();
  }

  List<QueryDocumentSnapshot> _chatDocs = [];
  List<QueryDocumentSnapshot> get chatDocs => _filteredChatDocs;
  
  final Map<String, UserModel> _userCache = {};
  Map<String, UserModel> get userCache => _userCache;

  final Map<String, StreamSubscription> _userSubscriptions = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _chatSubscription;
  StreamSubscription? _authSubscription;

  HomeProvider() {
    _init();
  }

  void _init() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initChatStream(user.uid);
      } else {
        _isLoading = false;
        _chatDocs = [];
        _userCache.clear();
        _cancelUserSubscriptions();
        _chatSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _initChatStream(String uid) {
    _chatSubscription?.cancel();
    _chatSubscription = _databaseService.getUserChats(uid).listen(
      (snapshot) {
        final docs = List<QueryDocumentSnapshot>.from(snapshot.docs);

        // Sort by lastMessageTimestamp descending (newest activity at the top)
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final tA = dataA['lastMessageTimestamp'];
          final tB = dataB['lastMessageTimestamp'];

          final timeA = tA is Timestamp
              ? tA.toDate()
              : (tA is DateTime ? tA : DateTime.fromMillisecondsSinceEpoch(0));
          final timeB = tB is Timestamp
              ? tB.toDate()
              : (tB is DateTime ? tB : DateTime.fromMillisecondsSinceEpoch(0));

          return timeB.compareTo(timeA);
        });

        _chatDocs = docs;
        _isLoading = false;
        notifyListeners();

        // Fetch / stream user data in background for names and avatars
        _syncUsersData(uid);
      },
      onError: (error) {
        debugPrint('Firestore Home Stream Error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _syncUsersData(String currentUserId) {
    for (var doc in _chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final users = data['users'] as List? ?? [];
      final receiverId = users.firstWhere(
        (id) => id != currentUserId,
        orElse: () => (users.isNotEmpty ? users.first : ''),
      );
      
      if (receiverId.isNotEmpty && !_userSubscriptions.containsKey(receiverId)) {
        // Stream user document in real time for avatar and name updates
        _userSubscriptions[receiverId] = _firestore
            .collection('users')
            .doc(receiverId)
            .snapshots()
            .listen((userDoc) {
          if (userDoc.exists && userDoc.data() != null) {
            _userCache[receiverId] = UserModel.fromMap(userDoc.data()!);
            notifyListeners();
          }
        }, onError: (e) {
          debugPrint('Error streaming user $receiverId: $e');
        });
      }
    }
  }

  void _cancelUserSubscriptions() {
    for (var sub in _userSubscriptions.values) {
      sub.cancel();
    }
    _userSubscriptions.clear();
  }

  /// Total count of unread chats for the current user
  int get totalUnreadChatsCount {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return 0;

    int count = 0;
    for (var doc in _chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final unread = (data['unreadCount_$currentUserId'] as num?)?.toInt() ?? 0;
      if (unread > 0) count++;
    }
    return count;
  }

  /// Total count of unread messages across all chats
  int get totalUnreadMessagesCount {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return 0;

    int total = 0;
    for (var doc in _chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final unread = (data['unreadCount_$currentUserId'] as num?)?.toInt() ?? 0;
      total += unread;
    }
    return total;
  }

  String? _selectedChatRoomId;
  String? get selectedChatRoomId => _selectedChatRoomId;
  bool get isSelectingChat => _selectedChatRoomId != null;

  void selectChat(String? chatRoomId) {
    _selectedChatRoomId = chatRoomId;
    notifyListeners();
  }

  void clearChatSelection() {
    _selectedChatRoomId = null;
    notifyListeners();
  }

  List<QueryDocumentSnapshot> get _filteredChatDocs {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _chatDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final unreadCount = (data['unreadCount_$currentUserId'] as num?)?.toInt() ?? 0;
      final favoritesList = data['favorites'] as List? ?? [];
      final isFav = favoritesList.contains(currentUserId) || data['favorite_$currentUserId'] == true;

      // Filter by chip
      if (_selectedFilter == 'Unread' && unreadCount == 0) {
        return false;
      }
      if (_selectedFilter == 'Favorites' && !isFav) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final lastMessage = (data['lastMessage'] as String? ?? '').toLowerCase();

        final users = data['users'] as List? ?? [];
        final receiverId = users.firstWhere(
          (id) => id != currentUserId,
          orElse: () => (users.isNotEmpty ? users.first : ''),
        );

        final receiver = _userCache[receiverId];
        final receiverName = (receiver?.name ?? '').toLowerCase();

        final matchesName = receiverName.contains(query);
        final matchesMessage = lastMessage.contains(query);

        if (!matchesName && !matchesMessage) return false;
      }

      return true;
    }).toList();
  }

  Future<void> deleteSelectedChat(String receiverId) async {
    try {
      await _databaseService.deleteChat(receiverId);
      clearChatSelection();
    } catch (e) {
      debugPrint('Error deleting chat in HomeProvider: $e');
      rethrow;
    }
  }

  Future<void> clearSelectedChat(String receiverId) async {
    try {
      await _databaseService.clearChat(receiverId);
      clearChatSelection();
    } catch (e) {
      debugPrint('Error clearing chat in HomeProvider: $e');
      rethrow;
    }
  }

  Future<void> toggleFavoriteSelectedChat(String receiverId, bool currentFavoriteState) async {
    try {
      await _databaseService.toggleFavoriteChat(receiverId, !currentFavoriteState);
      clearChatSelection();
    } catch (e) {
      debugPrint('Error toggling favorite in HomeProvider: $e');
    }
  }

  void setBottomNavIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _authSubscription?.cancel();
    _cancelUserSubscriptions();
    super.dispose();
  }
}
