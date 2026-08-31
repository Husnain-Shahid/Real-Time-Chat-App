import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'jwwboehk';
  static const String uploadPreset = 'notes_app_images';

  // Cloudinary credentials for signed resource destruction
  // You can set these to allow permanent deletion of all media from Cloudinary console/storage
  static const String apiKey = '892795856417726'; // Optional / configured Cloudinary API Key
  static const String apiSecret = ''; // Optional / configured Cloudinary API Secret

  final Dio _dio = Dio();

  Future<Map<String, String?>?> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String mediaType,
    required Function(double progress) onProgress,
  }) async {
    try {
      final endpoint = mediaType == 'video' || mediaType == 'voice' || mediaType == 'audio'
          ? 'https://api.cloudinary.com/v1_1/$cloudName/video/upload'
          : 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      final formData = FormData.fromMap({
        'upload_preset': uploadPreset,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        return {
          'secure_url': response.data['secure_url'] as String?,
          'public_id': response.data['public_id'] as String?,
          'delete_token': response.data['delete_token'] as String?,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<Map<String, String?>?> uploadXFile({
    required XFile xFile,
    required String mediaType,
    required Function(double progress) onProgress,
  }) async {
    try {
      final bytes = await xFile.readAsBytes();
      final fileName = xFile.name.isNotEmpty ? xFile.name : 'upload_${DateTime.now().millisecondsSinceEpoch}';
      return await uploadBytes(
        bytes: bytes,
        fileName: fileName,
        mediaType: mediaType,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Cloudinary uploadXFile error: $e');
      return null;
    }
  }

  Future<Map<String, String?>?> uploadMedia({
    File? file,
    Uint8List? bytes,
    String? fileName,
    required String mediaType,
    required Function(double progress) onProgress,
  }) async {
    try {
      if (bytes != null) {
        return await uploadBytes(
          bytes: bytes,
          fileName: fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
          mediaType: mediaType,
          onProgress: onProgress,
        );
      }

      if (file != null) {
        if (!kIsWeb) {
          final fileBytes = await file.readAsBytes();
          final name = fileName ?? file.path.split(RegExp(r'[\\/]+')).last;
          return await uploadBytes(
            bytes: fileBytes,
            fileName: name,
            mediaType: mediaType,
            onProgress: onProgress,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<Map<String, String?>?> uploadImage({
    File? image,
    Uint8List? imageBytes,
    String? fileName,
    required Function(double progress) onProgress,
  }) async {
    return uploadMedia(
      file: image,
      bytes: imageBytes,
      fileName: fileName ?? 'image.png',
      mediaType: 'image',
      onProgress: onProgress,
    );
  }

  Future<Map<String, String?>?> uploadVideo({
    File? video,
    Uint8List? videoBytes,
    String? fileName,
    required Function(double progress) onProgress,
  }) async {
    return uploadMedia(
      file: video,
      bytes: videoBytes,
      fileName: fileName ?? 'video.mp4',
      mediaType: 'video',
      onProgress: onProgress,
    );
  }

  Future<Map<String, String?>?> uploadAudio({
    File? audio,
    Uint8List? audioBytes,
    String? fileName,
    required Function(double progress) onProgress,
  }) async {
    return uploadMedia(
      file: audio,
      bytes: audioBytes,
      fileName: fileName ?? 'audio.m4a',
      mediaType: 'voice',
      onProgress: onProgress,
    );
  }

  /// Extracts public_id from a Cloudinary URL
  /// e.g. https://res.cloudinary.com/jwwboehk/image/upload/v1740156789/my_photo.jpg -> my_photo
  String? extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 1 < segments.length) {
        var relevantSegments = segments.sublist(uploadIndex + 1);
        // Remove version prefix if present (e.g. v1740156789)
        if (relevantSegments.isNotEmpty && RegExp(r'^v\d+$').hasMatch(relevantSegments.first)) {
          relevantSegments = relevantSegments.sublist(1);
        }
        if (relevantSegments.isNotEmpty) {
          final fullName = relevantSegments.join('/');
          final dotIndex = fullName.lastIndexOf('.');
          return dotIndex != -1 ? fullName.substring(0, dotIndex) : fullName;
        }
      }
    } catch (e) {
      debugPrint('Error extracting public_id: $e');
    }
    return null;
  }

  String extractResourceType(String? mediaType, String? url) {
    if (mediaType == 'video' || mediaType == 'voice' || mediaType == 'audio') {
      return 'video';
    }
    if (url != null) {
      if (url.contains('/video/upload/')) return 'video';
      if (url.contains('/raw/upload/')) return 'raw';
    }
    return 'image';
  }

  Future<bool> deleteUsingToken(String deleteToken) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/delete_by_token';
      final response = await _dio.post(url, data: {'token': deleteToken});
      if (response.statusCode == 200) {
        debugPrint('Successfully deleted media from Cloudinary using delete_token');
        return true;
      }
    } catch (e) {
      debugPrint('Cloudinary deleteUsingToken error: $e');
    }
    return false;
  }

  Future<bool> deleteUsingSignedDestroy({
    required String publicId,
    required String resourceType,
    String? customApiKey,
    String? customApiSecret,
  }) async {
    final key = (customApiKey != null && customApiKey.isNotEmpty) ? customApiKey : apiKey;
    final secret = (customApiSecret != null && customApiSecret.isNotEmpty) ? customApiSecret : apiSecret;

    if (key.isEmpty || secret.isEmpty) {
      debugPrint('Cloudinary signed destroy: API Key or Secret not configured.');
      return false;
    }

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      // SHA-1 signature format: "public_id=xxx&timestamp=xxx<api_secret>"
      final toSign = 'public_id=$publicId&timestamp=$timestamp$secret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy';
      final formData = FormData.fromMap({
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': key,
        'signature': signature,
      });

      final response = await _dio.post(url, data: formData);
      if (response.statusCode == 200 && response.data['result'] == 'ok') {
        debugPrint('Successfully destroyed Cloudinary asset ($resourceType): $publicId');
        return true;
      } else {
        debugPrint('Cloudinary destroy response: ${response.data}');
      }
    } catch (e) {
      debugPrint('Cloudinary signed destroy error: $e');
    }
    return false;
  }

  Future<void> deleteMedia({
    String? deleteToken,
    String? publicId,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      bool deleted = false;

      // 1. Try deleting via delete_token if available
      if (deleteToken != null && deleteToken.isNotEmpty) {
        deleted = await deleteUsingToken(deleteToken);
      }

      // 2. If token deletion failed or was not provided, attempt signed destroy
      if (!deleted) {
        final id = (publicId != null && publicId.isNotEmpty)
            ? publicId
            : (mediaUrl != null ? extractPublicIdFromUrl(mediaUrl) : null);
        final resourceType = extractResourceType(mediaType, mediaUrl);

        if (id != null) {
          deleted = await deleteUsingSignedDestroy(
            publicId: id,
            resourceType: resourceType,
          );
        }
      }

      if (!deleted) {
        debugPrint(
          'Cloudinary notice: To ensure all media is deleted immediately from Cloudinary, '
          'enable "Return delete token" in your Cloudinary upload preset ("$uploadPreset") '
          'or provide your Cloudinary API Key and API Secret in CloudinaryService.',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary deleteMedia error: $e');
    }
  }
}