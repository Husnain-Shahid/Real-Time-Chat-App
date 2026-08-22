import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || image.path.isEmpty) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking from gallery: $e');
      return null;
    }
  }

  Future<File?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null || image.path.isEmpty) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking from camera: $e');
      return null;
    }
  }

  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null || video.path.isEmpty) return null;
      return File(video.path);
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }

  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video == null || video.path.isEmpty) return null;
      return File(video.path);
    } catch (e) {
      print('Error picking video from camera: $e');
      return null;
    }
  }
}