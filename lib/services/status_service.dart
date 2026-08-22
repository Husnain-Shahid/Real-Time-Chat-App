import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/status_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of current user's status document
  Stream<StatusModel?> getMyStatusStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('statuses').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final status = StatusModel.fromMap(doc.data()!);
      return status.hasActiveStatus ? status : null;
    });
  }

  /// Stream of all status documents updated in the last 24 hours
  Stream<List<StatusModel>> getStatusesStream() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('statuses')
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data()))
          .where((status) => status.hasActiveStatus)
          .toList();
    });
  }

  /// Fetch user profile info (name, image) from users collection or FirebaseAuth
  Future<Map<String, String>> _getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'name': 'User', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'};
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = (data['name'] as String?)?.trim();
        final profileImage = (data['profileImage'] as String?)?.trim();

        return {
          'name': (name != null && name.isNotEmpty) ? name : (user.displayName ?? 'You'),
          'image': (profileImage != null && profileImage.isNotEmpty)
              ? profileImage
              : (user.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'),
        };
      }
    } catch (e) {
      debugPrint('Error fetching user info for status: $e');
    }

    return {
      'name': user.displayName ?? 'You',
      'image': user.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
    };
  }

  /// Add a text status
  Future<bool> publishTextStatus({
    required String text,
    required int backgroundColor,
    String? fontFamily,
  }) async {
    final uid = currentUserId;
    if (uid == null || text.trim().isEmpty) return false;

    final newItem = StatusItemModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$uid',
      type: 'text',
      content: text.trim(),
      backgroundColor: backgroundColor,
      fontFamily: fontFamily,
      createdAt: DateTime.now(),
      viewers: [],
    );

    return _appendStatusItem(newItem);
  }

  /// Add an image or video status
  Future<bool> publishMediaStatus({
    required String mediaUrl,
    required String mediaType, // 'image' | 'video'
    String? caption,
  }) async {
    final uid = currentUserId;
    if (uid == null || mediaUrl.trim().isEmpty) return false;

    final newItem = StatusItemModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$uid',
      type: mediaType,
      content: mediaUrl.trim(),
      caption: (caption != null && caption.trim().isNotEmpty) ? caption.trim() : null,
      createdAt: DateTime.now(),
      viewers: [],
    );

    return _appendStatusItem(newItem);
  }

  /// Appends a new status item to the user's statuses/{uid} doc and cleans up expired ones
  Future<bool> _appendStatusItem(StatusItemModel newItem) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final docRef = _firestore.collection('statuses').doc(uid);
      final docSnap = await docRef.get();
      final userInfo = await _getCurrentUserInfo();

      List<StatusItemModel> currentItems = [];
      if (docSnap.exists && docSnap.data() != null) {
        final existingStatus = StatusModel.fromMap(docSnap.data()!);
        // Keep only unexpired items
        currentItems = existingStatus.activeItems;
      }

      currentItems.add(newItem);

      final updatedStatus = StatusModel(
        uid: uid,
        userName: userInfo['name']!,
        userImage: userInfo['image']!,
        updatedAt: DateTime.now(),
        items: currentItems,
      );

      await docRef.set(updatedStatus.toMap());
      return true;
    } catch (e) {
      debugPrint('Error publishing status: $e');
      return false;
    }
  }

  /// Mark a specific status item as viewed by the current user
  Future<void> markStatusItemViewed({
    required String statusOwnerUid,
    required String statusItemId,
  }) async {
    final uid = currentUserId;
    if (uid == null || uid == statusOwnerUid) return;

    try {
      final docRef = _firestore.collection('statuses').doc(statusOwnerUid);
      final docSnap = await docRef.get();
      if (!docSnap.exists || docSnap.data() == null) return;

      final status = StatusModel.fromMap(docSnap.data()!);
      bool modified = false;

      final updatedItems = status.items.map((item) {
        if (item.id == statusItemId && !item.viewers.contains(uid)) {
          modified = true;
          return StatusItemModel(
            id: item.id,
            type: item.type,
            content: item.content,
            caption: item.caption,
            backgroundColor: item.backgroundColor,
            fontFamily: item.fontFamily,
            createdAt: item.createdAt,
            viewers: [...item.viewers, uid],
          );
        }
        return item;
      }).toList();

      if (modified) {
        await docRef.update({
          'items': updatedItems.map((e) => e.toMap()).toList(),
        });
      }
    } catch (e) {
      debugPrint('Error marking status item viewed: $e');
    }
  }

  /// Delete a status item by id (only allowed for owner)
  Future<bool> deleteStatusItem(String statusItemId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final docRef = _firestore.collection('statuses').doc(uid);
      final docSnap = await docRef.get();
      if (!docSnap.exists || docSnap.data() == null) return false;

      final status = StatusModel.fromMap(docSnap.data()!);
      final updatedItems = status.items.where((item) => item.id != statusItemId).toList();

      if (updatedItems.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.update({
          'items': updatedItems.map((e) => e.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting status item: $e');
      return false;
    }
  }
}
