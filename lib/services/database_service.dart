import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String getChatRoomId(String userId1, String userId2) {
    if (userId2.startsWith('group_')) return userId2;
    if (userId1.startsWith('group_')) return userId1;
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> ensureUserProfileExists(User user, {String? customName}) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      final data = doc.data();

      final bool isDocMissing = !doc.exists;
      final bool isMissingUniqueId = doc.exists && (data == null || data['uniqueId'] == null || (data['uniqueId'] as String).isEmpty);
      final bool isMissingEmail = doc.exists && (data == null || data['email'] == null || (data['email'] as String).isEmpty);

      if (isDocMissing || isMissingUniqueId || isMissingEmail) {
        String uniqueId = (data != null && data['uniqueId'] != null && (data['uniqueId'] as String).isNotEmpty)
            ? data['uniqueId']
            : UserModel.generateUniqueId();

        final updates = {
          'uid': user.uid,
          'uniqueId': uniqueId,
          'name': customName ?? ((data != null && data['name'] != null && (data['name'] as String).isNotEmpty)
              ? data['name']
              : (user.displayName ?? 'User')),
          'username': (user.email != null && user.email!.contains('@'))
              ? user.email!.split('@')[0]
              : (user.displayName?.toLowerCase().replaceAll(' ', '_') ?? 'user'),
          'email': user.email ?? '',
          'profileImage': (data != null && data['profileImage'] != null && (data['profileImage'] as String).isNotEmpty)
              ? data['profileImage']
              : (user.photoURL ?? ''),
          'about': (data != null && data['about'] != null) ? data['about'] : 'Hey there! I am using Chattrix.',
          'isOnline': true,
          'lastSeen': Timestamp.now(),
          'createdAt': (data != null && data['createdAt'] != null) ? data['createdAt'] : FieldValue.serverTimestamp(),
        };

        await docRef.set(updates, SetOptions(merge: true));
        debugPrint('DatabaseService: Successfully ensured user profile for ${user.uid} with uniqueId: $uniqueId');
      }
    } catch (e) {
      debugPrint('DatabaseService: Error ensuring user profile: $e');
    }
  }

  Future<void> createChatRoom(String receiverId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final String currentUserId = user.uid;
    String chatRoomId = getChatRoomId(currentUserId, receiverId);
    var chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'chatRoomId': chatRoomId,
        'isGroup': false,
        'users': [currentUserId, receiverId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_$currentUserId': 0,
        'unreadCount_$receiverId': 0,
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    String minuteStr = minute < 10 ? '0$minute' : '$minute';
    return '$hour:$minuteStr $period';
  }

  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String? replyTo,
    String? replyAuthor,
    String? fileName,
    String? reaction,
    String? mediaUrl,
    String? mediaType,
    String? publicId,
    String? deleteToken,
    double? voiceDuration,
    bool isGroup = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final String currentUserId = user.uid;
    final Timestamp timestamp = Timestamp.now();
    String formattedTime = _formatTime(timestamp.toDate());
    final bool isGroupChat = isGroup || receiverId.startsWith('group_');
    String chatRoomId = isGroupChat ? receiverId : getChatRoomId(currentUserId, receiverId);
    
    // Fetch sender user details for group chats
    String senderName = user.displayName ?? 'User';
    String senderImage = user.photoURL ?? '';
    if (senderName.isEmpty || senderName == 'User' || senderImage.isEmpty) {
      try {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          if (data['name'] != null && (data['name'] as String).isNotEmpty) {
            senderName = data['name'];
          }
          if (data['profileImage'] != null && (data['profileImage'] as String).isNotEmpty) {
            senderImage = data['profileImage'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching sender profile: $e');
      }
    }

    final String lastMessageText = mediaType == 'image'
        ? (text.isNotEmpty ? '📷 $text' : '📷 Photo')
        : (mediaType == 'video'
            ? (text.isNotEmpty ? '🎥 $text' : '🎥 Video')
            : (mediaType == 'voice' ? '🎤 Voice message' : text));

    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderImage': senderImage,
      'text': text,
      'time': formattedTime,
      'timestamp': timestamp,
      'isRead': false,
      'replyTo': replyTo,
      'replyAuthor': replyAuthor,
      'fileName': fileName,
      'reaction': reaction,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'publicId': publicId,
      'deleteToken': deleteToken,
      'voiceDuration': voiceDuration,
      'deletedFor': [],
      'isDeletedForEveryone': false,
    };

    WriteBatch batch = _firestore.batch();
    DocumentReference messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();
    batch.set(messageRef, messageData);
    
    DocumentReference chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    Map<String, dynamic> chatRoomUpdate = {
      'chatRoomId': chatRoomId,
      'lastMessage': isGroupChat ? '$senderName: $lastMessageText' : lastMessageText,
      'lastMessageTime': formattedTime,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
    };

    if (isGroupChat) {
      // Increment unread count for all group members except sender
      try {
        final roomDoc = await chatRoomRef.get();
        if (roomDoc.exists && roomDoc.data() != null) {
          final members = (roomDoc.data() as Map<String, dynamic>)['users'] as List? ?? [];
          for (var member in members) {
            if (member is String && member != currentUserId) {
              chatRoomUpdate['unreadCount_$member'] = FieldValue.increment(1);
            }
          }
        }
      } catch (e) {
        debugPrint('Error incrementing group unread: $e');
      }
    } else {
      chatRoomUpdate['users'] = [currentUserId, receiverId];
      if (currentUserId != receiverId) {
        chatRoomUpdate['unreadCount_$receiverId'] = FieldValue.increment(1);
      }
    }

    batch.set(chatRoomRef, chatRoomUpdate, SetOptions(merge: true));

    await batch.commit();

    // Dispatch FCM push notification (delivers even when recipient app is completely closed/killed)
    NotificationService.instance.sendPushNotification(
      receiverId: receiverId,
      senderName: senderName,
      senderImage: senderImage,
      messageText: lastMessageText,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      isGroup: isGroupChat,
    );
  }

  Stream<List<MessageModel>> getMessages(String receiverId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final bool isGroupChat = receiverId.startsWith('group_');
    String chatRoomId = isGroupChat ? receiverId : getChatRoomId(user.uid, receiverId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();
            List deletedForList = data['deletedFor'] ?? [];
            List<String> deletedFor = List<String>.from(deletedForList);
            if (deletedFor.contains(user.uid)) return null;

            DateTime? messageTimestamp;
            final dynamic rawTs = data['timestamp'];
            if (rawTs is Timestamp) {
              messageTimestamp = rawTs.toDate();
            } else if (rawTs is int) {
              messageTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
            }

            return MessageModel(
              id: doc.id,
              senderId: data['senderId'] ?? '',
              receiverId: data['receiverId'] ?? '',
              senderName: data['senderName'],
              senderImage: data['senderImage'],
              text: data['text'] ?? '',
              time: data['time'] ?? '',
              isMe: data['senderId'] == user.uid,
              isRead: data['isRead'] == true,
              mediaUrl: data['mediaUrl'] ?? data['imageUrl'],
              mediaType: data['mediaType'],
              publicId: data['publicId'],
              deleteToken: data['deleteToken'],
              replyTo: data['replyTo'],
              replyAuthor: data['replyAuthor'],
              fileName: data['fileName'],
              reaction: data['reaction'],
              voiceDuration: (data['voiceDuration'] is num) ? (data['voiceDuration'] as num).toDouble() : null,
              isDeletedForEveryone: data['isDeletedForEveryone'] ?? false,
              deletedFor: deletedFor,
              isSystem: data['isSystem'] == true || data['senderId'] == 'system',
              timestamp: messageTimestamp,
            );
          }).whereType<MessageModel>().toList();
        });
  }

  Stream<QuerySnapshot> getUserChats(String uid) {
    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: uid)
        .snapshots();
  }

  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomId) {
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots();
  }

  Future<void> markMessagesAsRead(String receiverId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final bool isGroupChat = receiverId.startsWith('group_');
    String chatRoomId = isGroupChat ? receiverId : getChatRoomId(user.uid, receiverId);
    
    try {
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      final unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      batch.set(chatRoomRef, {
        'unreadCount_${user.uid}': 0,
      }, SetOptions(merge: true));

      for (var doc in unreadMessages.docs) {
        final data = doc.data();
        if (data['senderId'] != user.uid) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error in markMessagesAsRead: $e');
    }
  }

  // ==================== GROUP CHAT MANAGEMENT ====================

  /// Creates a new group conversation in Firestore
  Future<String> createGroupChat({
    required String groupName,
    String? groupImage,
    required List<String> memberUids,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final String currentUserId = user.uid;
    final String chatRoomId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final Timestamp timestamp = Timestamp.now();
    final String formattedTime = _formatTime(timestamp.toDate());

    final Set<String> allMembers = {currentUserId, ...memberUids};

    String creatorName = user.displayName ?? 'You';
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists && userDoc.data() != null) {
        creatorName = userDoc.data()!['name'] ?? creatorName;
      }
    } catch (_) {}

    final Map<String, dynamic> groupData = {
      'chatRoomId': chatRoomId,
      'isGroup': true,
      'groupName': groupName,
      'groupImage': groupImage ?? '',
      'createdBy': currentUserId,
      'creatorName': creatorName,
      'createdAt': timestamp,
      'users': allMembers.toList(),
      'lastMessage': '$creatorName created this group',
      'lastMessageTime': formattedTime,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
    };

    for (var member in allMembers) {
      groupData['unreadCount_$member'] = (member == currentUserId ? 0 : 1);
    }

    WriteBatch batch = _firestore.batch();
    DocumentReference roomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    batch.set(roomRef, groupData);

    // Add initial announcement message
    DocumentReference initialMsgRef = roomRef.collection('messages').doc();
    batch.set(initialMsgRef, {
      'senderId': 'system',
      'senderName': creatorName,
      'senderImage': '',
      'receiverId': chatRoomId,
      'text': 'You created this group',
      'time': formattedTime,
      'timestamp': timestamp,
      'isRead': true,
      'isSystem': true,
      'deletedFor': [],
      'isDeletedForEveryone': false,
    });

    await batch.commit();
    return chatRoomId;
  }

  /// Adds new members to an existing group conversation
  Future<void> addGroupMembers({
    required String chatRoomId,
    required List<String> newMemberUids,
    List<String>? newMemberNames,
  }) async {
    final user = _auth.currentUser;
    if (user == null || newMemberUids.isEmpty) return;

    final String currentUserId = user.uid;
    final Timestamp timestamp = Timestamp.now();
    final String formattedTime = _formatTime(timestamp.toDate());

    String adderName = user.displayName ?? 'You';
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists && userDoc.data() != null) {
        adderName = userDoc.data()!['name'] ?? adderName;
      }
    } catch (_) {}

    // Resolve member names if not provided
    List<String> names = newMemberNames ?? [];
    if (names.isEmpty) {
      for (var uid in newMemberUids) {
        try {
          final uDoc = await _firestore.collection('users').doc(uid).get();
          if (uDoc.exists && uDoc.data() != null) {
            names.add(uDoc.data()!['name'] ?? 'A member');
          }
        } catch (_) {}
      }
    }

    final String announcementText = names.isNotEmpty
        ? '${names.join(' and ')} ${names.length > 1 ? 'were' : 'was'} added'
        : 'New participants were added';

    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    
    WriteBatch batch = _firestore.batch();
    batch.update(chatRoomRef, {
      'users': FieldValue.arrayUnion(newMemberUids),
      'lastMessage': announcementText,
      'lastMessageTime': formattedTime,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
    });

    // Add system message
    DocumentReference msgRef = chatRoomRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': 'system',
      'senderName': adderName,
      'receiverId': chatRoomId,
      'text': announcementText,
      'time': formattedTime,
      'timestamp': timestamp,
      'isRead': true,
      'isSystem': true,
      'deletedFor': [],
      'isDeletedForEveryone': false,
    });

    await batch.commit();
  }

  /// Remove a member from the group (Admin capability)
  Future<void> removeGroupMember({
    required String chatRoomId,
    required String memberUid,
    required String memberName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String currentUserId = user.uid;
    final Timestamp timestamp = Timestamp.now();
    final String formattedTime = _formatTime(timestamp.toDate());

    final String removalText = 'You removed $memberName';
    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    WriteBatch batch = _firestore.batch();
    batch.update(chatRoomRef, {
      'users': FieldValue.arrayRemove([memberUid]),
      'lastMessage': removalText,
      'lastMessageTime': formattedTime,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
    });

    DocumentReference msgRef = chatRoomRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': 'system',
      'senderName': 'Admin',
      'receiverId': chatRoomId,
      'text': removalText,
      'time': formattedTime,
      'timestamp': timestamp,
      'isRead': true,
      'isSystem': true,
      'deletedFor': [],
      'isDeletedForEveryone': false,
    });

    await batch.commit();
  }

  /// Current user exits the group
  Future<void> exitGroup({
    required String chatRoomId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String currentUserId = user.uid;
    final Timestamp timestamp = Timestamp.now();
    final String formattedTime = _formatTime(timestamp.toDate());

    String userName = user.displayName ?? 'A member';
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists && userDoc.data() != null) {
        userName = userDoc.data()!['name'] ?? userName;
      }
    } catch (_) {}

    final String exitText = '$userName left';
    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    WriteBatch batch = _firestore.batch();
    batch.update(chatRoomRef, {
      'users': FieldValue.arrayRemove([currentUserId]),
      'lastMessage': exitText,
      'lastMessageTime': formattedTime,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
    });

    DocumentReference msgRef = chatRoomRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': 'system',
      'senderName': userName,
      'receiverId': chatRoomId,
      'text': exitText,
      'time': formattedTime,
      'timestamp': timestamp,
      'isRead': true,
      'isSystem': true,
      'deletedFor': [],
      'isDeletedForEveryone': false,
    });

    await batch.commit();
  }

  /// Fetch full UserModel objects for given member UIDs
  Future<List<UserModel>> getGroupMembers(List<String> memberUids) async {
    final List<UserModel> members = [];
    for (var uid in memberUids) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          members.add(UserModel.fromMap(doc.data()!));
        }
      } catch (e) {
        debugPrint('Error fetching group member $uid: $e');
      }
    }
    return members;
  }

  Future<void> toggleFavoriteChat(String receiverId, bool isFavorite) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String chatRoomId = getChatRoomId(user.uid, receiverId);

    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'favorite_${user.uid}': isFavorite,
        'favorites': isFavorite
            ? FieldValue.arrayUnion([user.uid])
            : FieldValue.arrayRemove([user.uid]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error toggling favorite chat: $e');
    }
  }

  Future<void> deleteChat(String receiverId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String chatRoomId = getChatRoomId(user.uid, receiverId);

    try {
      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      final List<Map<String, String?>> mediaList = [];
      final WriteBatch batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        if (data['mediaUrl'] != null || data['imageUrl'] != null) {
          mediaList.add({
            'deleteToken': data['deleteToken'] as String?,
            'publicId': data['publicId'] as String?,
            'mediaUrl': (data['mediaUrl'] ?? data['imageUrl']) as String?,
            'mediaType': data['mediaType'] as String?,
          });
        }
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('chat_rooms').doc(chatRoomId));
      await batch.commit();

      // Clean up Cloudinary assets asynchronously
      for (var media in mediaList) {
        _cloudinaryService.deleteMedia(
          deleteToken: media['deleteToken'],
          publicId: media['publicId'],
          mediaUrl: media['mediaUrl'],
          mediaType: media['mediaType'],
        );
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  Future<void> clearChat(String receiverId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String chatRoomId = getChatRoomId(user.uid, receiverId);

    try {
      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      final List<Map<String, String?>> mediaList = [];
      final WriteBatch batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        if (data['mediaUrl'] != null || data['imageUrl'] != null) {
          mediaList.add({
            'deleteToken': data['deleteToken'] as String?,
            'publicId': data['publicId'] as String?,
            'mediaUrl': (data['mediaUrl'] ?? data['imageUrl']) as String?,
            'mediaType': data['mediaType'] as String?,
          });
        }
        batch.delete(doc.reference);
      }

      // Reset chat room document to empty state
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      batch.set(chatRoomRef, {
        'lastMessage': 'No messages yet',
        'lastMessageTime': '',
        'lastMessageSenderId': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_${user.uid}': 0,
        'unreadCount_$receiverId': 0,
      }, SetOptions(merge: true));

      await batch.commit();

      // Clean up Cloudinary assets
      for (var media in mediaList) {
        _cloudinaryService.deleteMedia(
          deleteToken: media['deleteToken'],
          publicId: media['publicId'],
          mediaUrl: media['mediaUrl'],
          mediaType: media['mediaType'],
        );
      }
    } catch (e) {
      debugPrint('Error clearing chat: $e');
      rethrow;
    }
  }

  Future<void> deleteMessageForMe(String receiverId, String messageId) async {
    await deleteMultipleMessagesForMe(receiverId, [messageId]);
  }

  Future<void> deleteMultipleMessagesForMe(String receiverId, List<String> messageIds) async {
    final user = _auth.currentUser;
    if (user == null || messageIds.isEmpty) return;
    String chatRoomId = getChatRoomId(user.uid, receiverId);

    try {
      final WriteBatch batch = _firestore.batch();

      for (var msgId in messageIds) {
        final msgRef = _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msgId);

        batch.update(msgRef, {
          'deletedFor': FieldValue.arrayUnion([user.uid]),
        });
      }

      await batch.commit();
      await _updateLastMessageAfterDeletion(chatRoomId, user.uid);
    } catch (e) {
      debugPrint('Error in deleteMultipleMessagesForMe: $e');
      rethrow;
    }
  }

  Future<void> deleteMessageForEveryone(String receiverId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String chatRoomId = getChatRoomId(user.uid, receiverId);

    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final message = MessageModel(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          text: data['text'] ?? '',
          time: data['time'] ?? '',
          isMe: data['senderId'] == user.uid,
          mediaUrl: data['mediaUrl'] ?? data['imageUrl'],
          mediaType: data['mediaType'],
          publicId: data['publicId'],
          deleteToken: data['deleteToken'],
        );
        await deleteMultipleMessagesForEveryone(receiverId, [message]);
      }
    } catch (e) {
      debugPrint('Error in deleteMessageForEveryone: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleMessagesForEveryone(String receiverId, List<MessageModel> messages) async {
    final user = _auth.currentUser;
    if (user == null || messages.isEmpty) return;
    String chatRoomId = getChatRoomId(user.uid, receiverId);

    try {
      final WriteBatch batch = _firestore.batch();

      for (var msg in messages) {
        final msgRef = _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msg.id);

        batch.delete(msgRef);

        if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
          _cloudinaryService.deleteMedia(
            deleteToken: msg.deleteToken,
            publicId: msg.publicId,
            mediaUrl: msg.mediaUrl,
            mediaType: msg.mediaType,
          );
        }
      }

      await batch.commit();
      await _updateLastMessageAfterDeletion(chatRoomId, user.uid);
    } catch (e) {
      debugPrint('Error in deleteMultipleMessagesForEveryone: $e');
      rethrow;
    }
  }

  Future<void> _updateLastMessageAfterDeletion(String chatRoomId, String currentUserId) async {
    try {
      final remaining = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

      if (remaining.docs.isEmpty) {
        await chatRoomRef.set({
          'lastMessage': 'No messages yet',
          'lastMessageTime': '',
          'lastMessageSenderId': '',
        }, SetOptions(merge: true));
      } else {
        final latest = remaining.docs.first.data();
        final mediaType = latest['mediaType'] as String?;
        final text = latest['text'] as String? ?? '';
        final lastMessageText = mediaType == 'image'
            ? (text.isNotEmpty ? '📷 $text' : '📷 Photo')
            : (mediaType == 'video'
                ? (text.isNotEmpty ? '🎥 $text' : '🎥 Video')
                : (mediaType == 'voice' ? '🎤 Voice message' : text));

        await chatRoomRef.set({
          'lastMessage': lastMessageText,
          'lastMessageTime': latest['time'] ?? '',
          'lastMessageTimestamp': latest['timestamp'] ?? FieldValue.serverTimestamp(),
          'lastMessageSenderId': latest['senderId'] ?? '',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating last message after deletion: $e');
    }
  }

  Future<void> sendImageMessage({
    required String receiverId,
    required String imageUrl,
    required String caption,
    String? publicId,
    String? deleteToken,
  }) async {
    await sendMessage(
      receiverId: receiverId,
      text: caption,
      mediaUrl: imageUrl,
      mediaType: 'image',
      publicId: publicId,
      deleteToken: deleteToken,
    );
  }

  Future<void> sendVideoMessage({
    required String receiverId,
    required String videoUrl,
    required String caption,
    String? publicId,
    String? deleteToken,
  }) async {
    await sendMessage(
      receiverId: receiverId,
      text: caption,
      mediaUrl: videoUrl,
      mediaType: 'video',
      publicId: publicId,
      deleteToken: deleteToken,
    );
  }

  Future<void> sendVoiceMessage({
    required String receiverId,
    required String voiceUrl,
    String? caption,
    double? duration,
    String? publicId,
    String? deleteToken,
  }) async {
    await sendMessage(
      receiverId: receiverId,
      text: caption ?? '',
      mediaUrl: voiceUrl,
      mediaType: 'voice',
      voiceDuration: duration,
      publicId: publicId,
      deleteToken: deleteToken,
    );
  }

  // ==================== CONTACTS MANAGEMENT ====================

  /// Add a user to current user's contacts list
  Future<void> addContact(String contactUid) async {
    final user = _auth.currentUser;
    if (user == null || contactUid.isEmpty || contactUid == user.uid) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .set({
      'contactUid': contactUid,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a user from current user's contacts list
  Future<void> removeContact(String contactUid) async {
    final user = _auth.currentUser;
    if (user == null || contactUid.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .delete();
  }

  /// Check if a user is in current user's contacts
  Future<bool> isContact(String contactUid) async {
    final user = _auth.currentUser;
    if (user == null || contactUid.isEmpty) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .get();

    return doc.exists;
  }

  /// Stream of contacts for the given user (includes both explicitly added contacts
  /// and any user with whom the current user has already chatted).
  Stream<List<UserModel>> getContactsStream(String currentUserId) {
    if (currentUserId.isEmpty) return const Stream.empty();

    late StreamController<List<UserModel>> controller;
    StreamSubscription? chatSub;
    StreamSubscription? contactSub;

    Future<void> updateContacts() async {
      if (controller.isClosed) return;
      try {
        final Set<String> contactUids = {};

        // 1. Collect all users with whom the current user has existing chats
        final chatRoomsSnap = await _firestore
            .collection('chat_rooms')
            .where('users', arrayContains: currentUserId)
            .get();

        for (var doc in chatRoomsSnap.docs) {
          final data = doc.data();
          final users = data['users'] as List? ?? [];
          for (var u in users) {
            if (u is String && u.isNotEmpty && u != currentUserId) {
              contactUids.add(u);
            }
          }
        }

        // 2. Collect all explicitly added contacts
        final contactsSnap = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('contacts')
            .get();

        for (var doc in contactsSnap.docs) {
          if (doc.id.isNotEmpty && doc.id != currentUserId) {
            contactUids.add(doc.id);
          }
        }

        // 3. Fetch full UserModel for each contact
        final List<UserModel> contacts = [];
        for (var uid in contactUids) {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            contacts.add(UserModel.fromMap(userDoc.data()!));
          }
        }

        // 4. Sort alphabetically by name
        contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (!controller.isClosed) {
          controller.add(contacts);
        }
      } catch (e) {
        debugPrint('Error updating contacts stream: $e');
      }
    }

    controller = StreamController<List<UserModel>>.broadcast(
      onListen: () {
        updateContacts();
        chatSub = _firestore
            .collection('chat_rooms')
            .where('users', arrayContains: currentUserId)
            .snapshots()
            .listen((_) => updateContacts());
        contactSub = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('contacts')
            .snapshots()
            .listen((_) => updateContacts());
      },
      onCancel: () {
        chatSub?.cancel();
        contactSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Search users across the app by Unique ID, Email, or Name
  Future<List<UserModel>> searchUsers(String query) async {
    final user = _auth.currentUser;
    final String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final List<UserModel> results = [];
    final Set<String> addedUids = {};

    try {
      // 1. Search by uniqueId
      final uniqueIdSnap = await _firestore
          .collection('users')
          .where('uniqueId', isEqualTo: cleanQuery.toUpperCase())
          .get();

      for (var doc in uniqueIdSnap.docs) {
        if (doc.id != user?.uid && !addedUids.contains(doc.id)) {
          addedUids.add(doc.id);
          results.add(UserModel.fromMap(doc.data()));
        }
      }

      // 2. Search by exact email
      final emailSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanQuery.toLowerCase())
          .get();

      for (var doc in emailSnap.docs) {
        if (doc.id != user?.uid && !addedUids.contains(doc.id)) {
          addedUids.add(doc.id);
          results.add(UserModel.fromMap(doc.data()));
        }
      }

      // 3. Search by name prefix if results are small
      if (results.isEmpty) {
        final nameSnap = await _firestore
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: cleanQuery)
            .where('name', isLessThanOrEqualTo: '$cleanQuery\uf8ff')
            .limit(10)
            .get();

        for (var doc in nameSnap.docs) {
          if (doc.id != user?.uid && !addedUids.contains(doc.id)) {
            addedUids.add(doc.id);
            results.add(UserModel.fromMap(doc.data()));
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    }

    return results;
  }
}