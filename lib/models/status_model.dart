import 'package:cloud_firestore/cloud_firestore.dart';

class StatusItemModel {
  final String id;
  final String type; // 'text' | 'image' | 'video'
  final String content; // text content or Cloudinary URL
  final String? caption;
  final int backgroundColor; // for text status (ARGB int)
  final String? fontFamily;
  final DateTime createdAt;
  final List<String> viewers; // List of user IDs who viewed this item

  StatusItemModel({
    required this.id,
    required this.type,
    required this.content,
    this.caption,
    this.backgroundColor = 0xFF075E54,
    this.fontFamily,
    required this.createdAt,
    this.viewers = const [],
  });

  bool get isExpired {
    final now = DateTime.now();
    return now.difference(createdAt).inHours >= 24;
  }

  bool isViewedBy(String uid) {
    return viewers.contains(uid);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'caption': caption,
      'backgroundColor': backgroundColor,
      'fontFamily': fontFamily,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewers': viewers,
    };
  }

  factory StatusItemModel.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : (rawCreatedAt is DateTime ? rawCreatedAt : DateTime.now());

    final rawViewers = map['viewers'];
    List<String> viewersList = [];
    if (rawViewers is List) {
      viewersList = rawViewers.map((e) => e.toString()).toList();
    }

    return StatusItemModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      content: map['content'] ?? '',
      caption: map['caption'],
      backgroundColor: map['backgroundColor'] is int ? map['backgroundColor'] : 0xFF075E54,
      fontFamily: map['fontFamily'],
      createdAt: createdAt,
      viewers: viewersList,
    );
  }
}

class StatusModel {
  final String uid;
  final String userName;
  final String userImage;
  final DateTime updatedAt;
  final List<StatusItemModel> items;

  StatusModel({
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.updatedAt,
    required this.items,
  });

  /// Returns only the active status items (not expired / posted in the last 24 hours)
  List<StatusItemModel> get activeItems {
    return items.where((item) => !item.isExpired).toList();
  }

  /// Whether there are any active status items left
  bool get hasActiveStatus => activeItems.isNotEmpty;

  /// Returns true if all active status items have been viewed by [currentUserId]
  bool isAllViewedBy(String currentUserId) {
    if (activeItems.isEmpty) return true;
    return activeItems.every((item) => item.isViewedBy(currentUserId));
  }

  /// Latest active status item (e.g. for preview image or text)
  StatusItemModel? get latestItem {
    final active = activeItems;
    if (active.isEmpty) return null;
    return active.last;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'userImage': userImage,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    final rawUpdatedAt = map['updatedAt'];
    final updatedAt = rawUpdatedAt is Timestamp
        ? rawUpdatedAt.toDate()
        : (rawUpdatedAt is DateTime ? rawUpdatedAt : DateTime.now());

    final rawItems = map['items'];
    List<StatusItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => StatusItemModel.fromMap(e))
          .toList();
    }

    return StatusModel(
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      updatedAt: updatedAt,
      items: itemsList,
    );
  }
}
