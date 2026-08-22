import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/status_model.dart';
import '../services/status_service.dart';
import '../services/cloudinary_service.dart';

class StatusProvider extends ChangeNotifier {
  final StatusService _statusService = StatusService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  StatusModel? _myStatus;
  StatusModel? get myStatus => _myStatus;

  List<StatusModel> _allStatuses = [];
  List<StatusModel> get allStatuses => _allStatuses;

  Set<String> _contactUids = {};
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _myStatusSubscription;
  StreamSubscription? _statusesSubscription;
  StreamSubscription? _authSubscription;

  StatusProvider() {
    _init();
  }

  void _init() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToStreams(user.uid);
      } else {
        _myStatus = null;
        _allStatuses = [];
        _contactUids.clear();
        _myStatusSubscription?.cancel();
        _statusesSubscription?.cancel();
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _subscribeToStreams(String currentUserId) {
    _myStatusSubscription?.cancel();
    _statusesSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _myStatusSubscription = _statusService.getMyStatusStream().listen((status) {
      _myStatus = status;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to my status: $e');
      _isLoading = false;
      notifyListeners();
    });

    _statusesSubscription = _statusService.getStatusesStream().listen((statuses) {
      _allStatuses = statuses;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to statuses: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Updates the set of user IDs who are in current user's chats/contacts
  void updateContactUids(Set<String> uids) {
    _contactUids = uids;
    notifyListeners();
  }

  /// Active statuses posted by contacts (excluding current user and expired)
  List<StatusModel> get contactStatuses {
    final myUid = _statusService.currentUserId;
    return _allStatuses.where((status) {
      if (status.uid == myUid) return false;
      if (!status.hasActiveStatus) return false;
      // Show if in chat/contact list (or all if contact list is empty during initial load)
      if (_contactUids.isNotEmpty && !_contactUids.contains(status.uid)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Recent (unviewed) statuses from contacts
  List<StatusModel> get recentStatuses {
    final myUid = _statusService.currentUserId ?? '';
    return contactStatuses.where((status) => !status.isAllViewedBy(myUid)).toList();
  }

  /// Viewed statuses from contacts
  List<StatusModel> get viewedStatuses {
    final myUid = _statusService.currentUserId ?? '';
    return contactStatuses.where((status) => status.isAllViewedBy(myUid)).toList();
  }

  /// Publish a text status
  Future<bool> publishTextStatus({
    required String text,
    required int backgroundColor,
    String? fontFamily,
  }) async {
    if (text.trim().isEmpty) return false;

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _statusService.publishTextStatus(
        text: text,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
      );

      if (!success) {
        _errorMessage = 'Failed to publish text status';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to publish text status: $e';
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Publish an image or video status via Cloudinary
  Future<bool> publishMediaStatus({
    required File file,
    required String mediaType, // 'image' | 'video'
    String? caption,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, String?>? uploadResult;

      if (mediaType == 'video') {
        uploadResult = await _cloudinaryService.uploadVideo(
          video: file,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      } else {
        uploadResult = await _cloudinaryService.uploadImage(
          image: file,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      final mediaUrl = uploadResult?['secure_url'];
      if (mediaUrl == null || mediaUrl.isEmpty) {
        _errorMessage = 'Failed to upload status media';
        return false;
      }

      final success = await _statusService.publishMediaStatus(
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: caption,
      );

      if (!success) {
        _errorMessage = 'Failed to save status';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error publishing status: $e';
      return false;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Mark a status item as viewed
  Future<void> markStatusItemViewed({
    required String statusOwnerUid,
    required String statusItemId,
  }) async {
    await _statusService.markStatusItemViewed(
      statusOwnerUid: statusOwnerUid,
      statusItemId: statusItemId,
    );
  }

  /// Delete a status item (my status only)
  Future<bool> deleteStatusItem(String statusItemId) async {
    return _statusService.deleteStatusItem(statusItemId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _myStatusSubscription?.cancel();
    _statusesSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
