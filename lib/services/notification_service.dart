import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/chat_model.dart';
import '../screens/chat_screen.dart';
import '../widget/in_app_notification_banner.dart';
import 'fcm_v1_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background message received: ${message.messageId}');

  // If the message already has a display notification payload, Google Play Services
  // automatically renders the notification with image & text. Do NOT show a second notification!
  if (message.notification != null) {
    return;
  }

  // Only handle pure data-payload messages:
  final data = message.data;
  if (data.isEmpty) return;
  final String senderName = data['senderName'] ?? 'New Message';
  final String text = data['text'] ?? '';
  final String senderImage = data['senderImage'] ?? '';
  final String chatRoomId = data['chatRoomId'] ?? '';
  final String mediaType = data['mediaType'] ?? '';
  final String mediaUrl = data['mediaUrl'] ?? '';

  if (senderName.isNotEmpty || text.isNotEmpty) {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await localNotifications.initialize(initSettings);

    AndroidBitmap<Object>? largeIcon;
    if (senderImage.isNotEmpty) {
      try {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          senderImage,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          largeIcon = ByteArrayAndroidBitmap(Uint8List.fromList(response.data!));
        }
      } catch (_) {}
    }

    BigPictureStyleInformation? bigPictureStyle;
    if (mediaType == 'image' && mediaUrl.isNotEmpty) {
      try {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          mediaUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          bigPictureStyle = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(Uint8List.fromList(response.data!)),
            largeIcon: largeIcon,
            contentTitle: senderName,
            summaryText: text,
          );
        }
      } catch (_) {}
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chattrix_messages',
      'Chat Messages',
      channelDescription: 'Incoming chat message notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: largeIcon,
      styleInformation: bigPictureStyle,
      color: const Color(0xFF0078FF),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: senderName,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    await localNotifications.show(
      chatRoomId.hashCode.abs() % 100000,
      senderName,
      text,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(data),
    );
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));

  GlobalKey<NavigatorState>? navigatorKey;
  OverlayEntry? _currentBannerEntry;

  String? _activeChatRoomId;
  String? _currentUserId;
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  final Set<String> _processedMessageIds = {};

  static const String _channelId = 'chattrix_messages';
  static const String _channelName = 'Chat Messages';
  static const String _channelDescription = 'Incoming chat message notifications';

  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // 1. Android Initialization Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS/Darwin Initialization Settings
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3. Linux Settings
    const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Create High-Priority Notification Channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }

    // 5. Setup Firebase Cloud Messaging (FCM)
    await _setupFirebaseMessaging();

    // 6. If already logged in on launch, start listening immediately
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      startListening(currentUser.uid);
      _syncFCMToken(currentUser.uid);
    }

    // 7. Hook into Firebase Auth State changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startListening(user.uid);
        _syncFCMToken(user.uid);
      } else {
        stopListening();
      }
    });
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Request FCM Permissions (Critical for iOS and Android 13+)
      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      // Set presentation options for foreground notifications
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle FCM Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.data}');
        final data = message.data;
        if (data.isNotEmpty) {
          final String chatRoomId = data['chatRoomId'] ?? '';
          final String senderId = data['senderId'] ?? '';
          final String senderName = data['senderName'] ?? message.notification?.title ?? 'New Message';
          final String senderImage = data['senderImage'] ?? '';
          final String text = data['text'] ?? message.notification?.body ?? '';
          final String mediaType = data['mediaType'] ?? '';
          final String mediaUrl = data['mediaUrl'] ?? '';
          final bool isGroup = data['isGroup'] == 'true' || chatRoomId.startsWith('group_');

          if (senderId.isNotEmpty && senderId == _currentUserId) return;
          if (_activeChatRoomId == chatRoomId) return;

          _showNotification(
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: senderName,
            senderImage: senderImage,
            messageText: text,
            mediaType: mediaType,
            mediaUrl: mediaUrl,
            isGroup: isGroup,
          );
        }
      });

      // Handle Notification Tap when App was in Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened app: ${message.data}');
        final data = message.data;
        if (data.isNotEmpty) {
          _openChat(
            receiverId: data['receiverId'] ?? data['chatRoomId'] ?? '',
            name: data['senderName'] ?? 'Chat',
            avatarUrl: data['senderImage'] ?? '',
            isGroup: data['isGroup'] == 'true',
          );
        }
      });

      // Handle Notification Tap when App was Terminated / Killed
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via FCM: ${initialMessage.data}');
        final data = initialMessage.data;
        if (data.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openChat(
              receiverId: data['receiverId'] ?? data['chatRoomId'] ?? '',
              name: data['senderName'] ?? 'Chat',
              avatarUrl: data['senderImage'] ?? '',
              isGroup: data['isGroup'] == 'true',
            );
          });
        }
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        if (_currentUserId != null) {
          _updateFCMTokenInFirestore(_currentUserId!, newToken);
        }
      });
    } catch (e) {
      debugPrint('Error setting up FirebaseMessaging: $e');
    }
  }

  Future<void> _syncFCMToken(String userId) async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM Device Token: $token');
        await _updateFCMTokenInFirestore(userId, token);
      }
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
    }
  }

  Future<void> _updateFCMTokenInFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating FCM token in Firestore: $e');
    }
  }

  Future<void> sendPushNotification({
    required String receiverId,
    required String senderName,
    required String senderImage,
    required String messageText,
    String? mediaType,
    String? mediaUrl,
    bool isGroup = false,
  }) async {
    try {
      final List<String> targetTokens = [];
      final String currentUserId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

      if (isGroup || receiverId.startsWith('group_')) {
        // Fetch tokens for all group members except sender
        final groupDoc = await _firestore.collection('chat_rooms').doc(receiverId).get();
        if (groupDoc.exists && groupDoc.data() != null) {
          final members = (groupDoc.data() as Map<String, dynamic>)['users'] as List? ?? [];
          for (var member in members) {
            if (member is String && member != currentUserId) {
              final userDoc = await _firestore.collection('users').doc(member).get();
              if (userDoc.exists && userDoc.data() != null) {
                final token = userDoc.data()!['fcmToken'] as String?;
                if (token != null && token.isNotEmpty) {
                  targetTokens.add(token);
                }
              }
            }
          }
        }
      } else {
        // Fetch recipient's token
        final userDoc = await _firestore.collection('users').doc(receiverId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final token = userDoc.data()!['fcmToken'] as String?;
          if (token != null && token.isNotEmpty) {
            targetTokens.add(token);
          }
        }
      }

      if (targetTokens.isEmpty) {
        debugPrint('NotificationService: No FCM target tokens found for $receiverId');
        return;
      }

      final String chatRoomId = isGroup || receiverId.startsWith('group_')
          ? receiverId
          : (_activeChatRoomId ?? receiverId);

      for (var token in targetTokens) {
        await FCMV1Service.instance.sendV1PushNotification(
          targetToken: token,
          senderName: senderName,
          senderImage: senderImage,
          messageText: messageText,
          chatRoomId: chatRoomId,
          receiverId: isGroup ? receiverId : currentUserId,
          senderId: currentUserId,
          mediaType: mediaType,
          mediaUrl: mediaUrl,
          isGroup: isGroup,
        );
      }
    } catch (e) {
      debugPrint('NotificationService: Error dispatching push notification: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  void setActiveChatRoomId(String? chatRoomId) {
    _activeChatRoomId = chatRoomId;
  }

  void clearActiveChatRoomId() {
    _activeChatRoomId = null;
  }

  void startListening(String userId) {
    if (_currentUserId == userId && _chatRoomsSubscription != null) return;

    stopListening();
    _currentUserId = userId;

    // Listen to all chat rooms where user is a participant
    _chatRoomsSubscription = _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final chatRoomId = change.doc.id;
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          _listenToMessagesInRoom(chatRoomId);
        } else if (change.type == DocumentChangeType.removed) {
          _messageSubscriptions[chatRoomId]?.cancel();
          _messageSubscriptions.remove(chatRoomId);
        }
      }
    }, onError: (e) {
      debugPrint('NotificationService: Error listening to chat rooms: $e');
    });
  }

  void _listenToMessagesInRoom(String chatRoomId) {
    if (_messageSubscriptions.containsKey(chatRoomId)) return;

    bool isInitialSnapshot = true;

    _messageSubscriptions[chatRoomId] = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      if (isInitialSnapshot) {
        isInitialSnapshot = false;
        for (var doc in snapshot.docs) {
          _processedMessageIds.add(doc.id);
        }
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;

        final String messageId = doc.id;
        if (_processedMessageIds.contains(messageId)) continue;
        _processedMessageIds.add(messageId);

        final String senderId = data['senderId'] ?? '';
        if (senderId.isEmpty || senderId == _currentUserId) {
          continue; // Do not notify sender of their own messages
        }

        // Check if user is actively in this chat screen
        if (_activeChatRoomId == chatRoomId) {
          continue; // Suppress notification when already viewing the chat
        }

        final String senderName = data['senderName'] ?? 'New Message';
        final String text = data['text'] ?? '';
        final String mediaType = data['mediaType'] ?? '';
        final String mediaUrl = data['mediaUrl'] ?? '';
        final String senderImage = data['senderImage'] ?? '';
        final bool isGroup = chatRoomId.startsWith('group_');

        String previewText = text;
        if (mediaType == 'image') {
          previewText = text.isNotEmpty ? '📷 $text' : '📷 Photo';
        } else if (mediaType == 'video') {
          previewText = text.isNotEmpty ? '🎥 $text' : '🎥 Video';
        } else if (mediaType == 'audio' || mediaType == 'voice') {
          previewText = '🎤 Voice note';
        } else if (mediaType == 'document' || mediaType == 'file') {
          previewText = '📎 Document';
        }

        if (previewText.isEmpty) {
          previewText = 'Sent a message';
        }

        _showNotification(
          chatRoomId: chatRoomId,
          senderId: senderId,
          senderName: senderName,
          senderImage: senderImage,
          messageText: previewText,
          mediaType: mediaType,
          mediaUrl: mediaUrl,
          isGroup: isGroup,
        );
      }
    }, onError: (e) {
      debugPrint('NotificationService: Error listening to messages for $chatRoomId: $e');
    });
  }

  Future<AndroidBitmap<Object>?> _getBitmapFromUrl(String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        return ByteArrayAndroidBitmap(Uint8List.fromList(response.data!));
      }
    } catch (e) {
      debugPrint('NotificationService: Error downloading notification image: $e');
    }
    return null;
  }

  void _showNotification({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String messageText,
    String? mediaType,
    String? mediaUrl,
    required bool isGroup,
  }) async {
    final int notificationId = chatRoomId.hashCode.abs() % 100000;

    final Map<String, dynamic> payloadData = {
      'chatRoomId': chatRoomId,
      'receiverId': isGroup ? chatRoomId : senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'isGroup': isGroup,
    };
    final String payloadJson = jsonEncode(payloadData);

    final bool isAppInForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (isAppInForeground) {
      // 1. WHEN APP IS OPEN (Foreground):
      // Show ONLY the gorgeous in-app banner with profile picture.
      _showInAppBanner(
        chatRoomId: chatRoomId,
        receiverId: isGroup ? chatRoomId : senderId,
        senderName: senderName,
        senderImage: senderImage,
        messageText: messageText,
        isGroup: isGroup,
      );
    } else {
      // 2. WHEN APP IS CLOSED / BACKGROUND / SCREEN LOCKED:
      // Show System Notification WITH Sender Picture / Avatar!
      AndroidBitmap<Object>? largeIcon;
      if (senderImage.isNotEmpty) {
        largeIcon = await _getBitmapFromUrl(senderImage);
      }

      BigPictureStyleInformation? bigPictureStyle;
      if (mediaType == 'image' && mediaUrl != null && mediaUrl.isNotEmpty) {
        final mediaBitmap = await _getBitmapFromUrl(mediaUrl);
        if (mediaBitmap != null) {
          bigPictureStyle = BigPictureStyleInformation(
            mediaBitmap,
            largeIcon: largeIcon,
            contentTitle: senderName,
            summaryText: messageText,
          );
        }
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: largeIcon,
        styleInformation: bigPictureStyle,
        color: const Color(0xFF0078FF),
        fullScreenIntent: false,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        ticker: senderName,
        enableLights: true,
        enableVibration: true,
        playSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _localNotifications.show(
          notificationId,
          senderName,
          messageText,
          platformChannelSpecifics,
          payload: payloadJson,
        );
      } catch (e) {
        debugPrint('NotificationService: Error displaying system notification: $e');
      }
    }
  }

  void _showInAppBanner({
    required String chatRoomId,
    required String receiverId,
    required String senderName,
    required String senderImage,
    required String messageText,
    required bool isGroup,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey?.currentContext;
      if (context == null) return;

      final overlayState = navigatorKey?.currentState?.overlay ?? Overlay.maybeOf(context);
      if (overlayState == null) return;

      try {
        _currentBannerEntry?.remove();
      } catch (_) {}
      _currentBannerEntry = null;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => InAppNotificationBanner(
          senderName: senderName,
          messageText: messageText,
          avatarUrl: senderImage,
          chatRoomId: chatRoomId,
          isGroup: isGroup,
          onTap: () {
            _openChat(
              receiverId: receiverId,
              name: senderName,
              avatarUrl: senderImage,
              isGroup: isGroup,
            );
          },
          onDismiss: () {
            if (_currentBannerEntry == entry) {
              entry.remove();
              _currentBannerEntry = null;
            }
          },
        ),
      );

      _currentBannerEntry = entry;
      overlayState.insert(entry);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      _openChat(
        receiverId: data['receiverId'] ?? '',
        name: data['senderName'] ?? 'Chat',
        avatarUrl: data['senderImage'] ?? '',
        isGroup: data['isGroup'] ?? false,
      );
    } catch (e) {
      debugPrint('NotificationService: Error parsing notification payload: $e');
    }
  }

  void _openChat({
    required String receiverId,
    required String name,
    required String avatarUrl,
    required bool isGroup,
  }) {
    if (receiverId.isEmpty) return;

    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final chatModel = ChatModel(
      id: receiverId,
      name: name,
      lastMessage: '',
      time: '',
      avatarUrl: avatarUrl,
      isGroup: isGroup,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chat: chatModel,
          receiverId: receiverId,
        ),
      ),
    );
  }

  void stopListening() {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;

    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
    _processedMessageIds.clear();
    _currentUserId = null;
  }
}
