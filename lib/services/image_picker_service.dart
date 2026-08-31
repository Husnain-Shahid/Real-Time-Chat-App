import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageXFile({ImageSource source = ImageSource.gallery, int imageQuality = 80}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );
      if (image == null || image.path.isEmpty) return null;
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<XFile?> pickVideoXFile({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? video = await _picker.pickVideo(source: source);
      if (video == null || video.path.isEmpty) return null;
      return video;
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  Future<File?> pickFromGallery() async {
    final xFile = await pickImageXFile(source: ImageSource.gallery);
    if (xFile == null) return null;
    return !kIsWeb ? File(xFile.path) : null;
  }

  Future<File?> pickFromCamera() async {
    final xFile = await pickImageXFile(source: ImageSource.camera);
    if (xFile == null) return null;
    return !kIsWeb ? File(xFile.path) : null;
  }

  Future<File?> pickVideoFromGallery() async {
    final xFile = await pickVideoXFile(source: ImageSource.gallery);
    if (xFile == null) return null;
    return !kIsWeb ? File(xFile.path) : null;
  }

  Future<File?> pickVideoFromCamera() async {
    final xFile = await pickVideoXFile(source: ImageSource.camera);
    if (xFile == null) return null;
    return !kIsWeb ? File(xFile.path) : null;
  }
}