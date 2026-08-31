import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/cloudinary_service.dart';
import '../services/image_picker_service.dart';
import '../services/database_service.dart';

class MediaProvider extends ChangeNotifier {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final DatabaseService _databaseService = DatabaseService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  DateTime? _voiceRecordingStartedAt;

  File? _selectedFile;
  File? get selectedFile => _selectedFile;

  Uint8List? _selectedBytes;
  Uint8List? get selectedBytes => _selectedBytes;

  String? _selectedFileName;
  String? get selectedFileName => _selectedFileName;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  String? _fileType;
  String? get fileType => _fileType;

  bool _isVoiceRecording = false;
  bool get isVoiceRecording => _isVoiceRecording;

  File? _recordedVoiceFile;
  File? get recordedVoiceFile => _recordedVoiceFile;

  Uint8List? _recordedVoiceBytes;
  Uint8List? get recordedVoiceBytes => _recordedVoiceBytes;

  Duration? _recordedVoiceDuration;
  Duration? get recordedVoiceDuration => _recordedVoiceDuration;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isVideo => _fileType == 'video';

  bool _isUploadingVoice = false;
  bool get isUploadingVoice => _isUploadingVoice;

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> pickImageGallery() async {
    final xFile = await _imagePickerService.pickImageXFile(source: ImageSource.gallery);
    if (xFile != null) {
      _selectedBytes = await xFile.readAsBytes();
      _selectedFileName = xFile.name;
      _selectedFile = !kIsWeb ? File(xFile.path) : null;
      _fileType = 'image';
      notifyListeners();
    }
  }

  Future<void> pickImageCamera() async {
    final xFile = await _imagePickerService.pickImageXFile(source: ImageSource.camera);
    if (xFile != null) {
      _selectedBytes = await xFile.readAsBytes();
      _selectedFileName = xFile.name;
      _selectedFile = !kIsWeb ? File(xFile.path) : null;
      _fileType = 'image';
      notifyListeners();
    }
  }

  Future<void> pickVideoGallery() async {
    final xFile = await _imagePickerService.pickVideoXFile(source: ImageSource.gallery);
    if (xFile != null) {
      _selectedBytes = await xFile.readAsBytes();
      _selectedFileName = xFile.name;
      _selectedFile = !kIsWeb ? File(xFile.path) : null;
      _fileType = 'video';
      notifyListeners();
    }
  }

  Future<void> pickVideoCamera() async {
    final xFile = await _imagePickerService.pickVideoXFile(source: ImageSource.camera);
    if (xFile != null) {
      _selectedBytes = await xFile.readAsBytes();
      _selectedFileName = xFile.name;
      _selectedFile = !kIsWeb ? File(xFile.path) : null;
      _fileType = 'video';
      notifyListeners();
    }
  }

  Future<bool> startVoiceRecording() async {
    if (_isVoiceRecording) return true;
    _errorMessage = null;

    try {
      final bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _setError('Microphone permission denied');
        return false;
      }

      await clearRecordedVoice(notify: false);
      String filePath = '';
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      _voiceRecordingStartedAt = DateTime.now();
      _isVoiceRecording = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isVoiceRecording = false;
      _voiceRecordingStartedAt = null;
      _setError('Failed to start recording');
      debugPrint('Failed to start recording: $e');
      return false;
    }
  }

  Future<bool> stopVoiceRecording() async {
    if (!_isVoiceRecording) return (_recordedVoiceFile != null || _recordedVoiceBytes != null);

    try {
      final path = await _audioRecorder.stop();
      _isVoiceRecording = false;
      final startedAt = _voiceRecordingStartedAt;
      _voiceRecordingStartedAt = null;

      if (path == null || path.isEmpty) {
        _setError('No recording captured');
        return false;
      }

      if (kIsWeb) {
        try {
          final dio = Dio();
          final res = await dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
          if (res.data != null && res.data!.isNotEmpty) {
            _recordedVoiceBytes = Uint8List.fromList(res.data!);
            _recordedVoiceDuration = startedAt == null ? null : DateTime.now().difference(startedAt);
            notifyListeners();
            return true;
          }
        } catch (e) {
          debugPrint('Error reading web voice recording: $e');
        }
        _setError('Recorded audio not found');
        return false;
      } else {
        final file = File(path);
        if (!await file.exists()) {
          _setError('Recorded file not found');
          return false;
        }

        final length = await file.length();
        if (length == 0) {
          _setError('Recorded file is empty');
          return false;
        }

        _recordedVoiceFile = file;
        _recordedVoiceBytes = await file.readAsBytes();
        _recordedVoiceDuration = startedAt == null ? null : DateTime.now().difference(startedAt);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isVoiceRecording = false;
      _voiceRecordingStartedAt = null;
      _setError('Failed to stop recording');
      debugPrint('Failed to stop recording: $e');
      return false;
    }
  }

  bool _isVoicePaused = false;
  bool get isVoicePaused => _isVoicePaused;

  Future<void> pauseVoiceRecording() async {
    if (_isVoiceRecording && !_isVoicePaused) {
      try {
        await _audioRecorder.pause();
        _isVoicePaused = true;
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to pause recording: $e');
      }
    }
  }

  Future<void> resumeVoiceRecording() async {
    if (_isVoiceRecording && _isVoicePaused) {
      try {
        await _audioRecorder.resume();
        _isVoicePaused = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to resume recording: $e');
      }
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (_isVoiceRecording) {
      try {
        await _audioRecorder.stop();
      } catch (e) {
        debugPrint('Failed to cancel recording: $e');
      }
    }
    _isVoiceRecording = false;
    _isVoicePaused = false;
    _voiceRecordingStartedAt = null;
    await clearRecordedVoice(notify: false);
    notifyListeners();
  }

  Future<void> clearRecordedVoice({bool notify = true}) async {
    final file = _recordedVoiceFile;
    _recordedVoiceFile = null;
    _recordedVoiceBytes = null;
    _recordedVoiceDuration = null;
    if (file != null && !kIsWeb && await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Failed to delete local voice file: $e');
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  void clearMedia() {
    _selectedFile = null;
    _selectedBytes = null;
    _selectedFileName = null;
    _fileType = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  Future<void> sendMediaMessage(
    String receiverId,
    String receiverName,
    String caption,
  ) async {
    if ((_selectedBytes == null && _selectedFile == null) || _isUploading) return;

    final mediaType = _fileType ?? 'image';
    _errorMessage = null;

    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      Map<String, String?>? uploadResult;

      if (_selectedBytes != null) {
        uploadResult = await _cloudinaryService.uploadBytes(
          bytes: _selectedBytes!,
          fileName: _selectedFileName ?? (mediaType == 'video' ? 'video.mp4' : 'image.png'),
          mediaType: mediaType,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      } else if (_selectedFile != null) {
        if (mediaType == 'video') {
          uploadResult = await _cloudinaryService.uploadVideo(
            video: _selectedFile!,
            onProgress: (progress) {
              _uploadProgress = progress;
              notifyListeners();
            },
          );
        } else {
          uploadResult = await _cloudinaryService.uploadImage(
            image: _selectedFile!,
            onProgress: (progress) {
              _uploadProgress = progress;
              notifyListeners();
            },
          );
        }
      }

      if (uploadResult != null && uploadResult['secure_url'] != null) {
        final mediaUrl = uploadResult['secure_url']!;
        final publicId = uploadResult['public_id'];
        final deleteToken = uploadResult['delete_token'];

        if (mediaType == 'video') {
          await _databaseService.sendVideoMessage(
            receiverId: receiverId,
            videoUrl: mediaUrl,
            caption: caption,
            publicId: publicId,
            deleteToken: deleteToken,
          );
        } else {
          await _databaseService.sendImageMessage(
            receiverId: receiverId,
            imageUrl: mediaUrl,
            caption: caption,
            publicId: publicId,
            deleteToken: deleteToken,
          );
        }

        clearMedia();
      } else {
        _setError('Failed to upload media');
      }
    } catch (e) {
      _setError('Failed to send media');
      debugPrint('Error sending media message: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> sendRecordedVoiceMessage({
    required String receiverId,
    String caption = '',
  }) async {
    if (_isUploadingVoice || (_recordedVoiceFile == null && _recordedVoiceBytes == null)) return false;
    _isUploadingVoice = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, String?>? uploadResult;
      if (_recordedVoiceBytes != null) {
        uploadResult = await _cloudinaryService.uploadBytes(
          bytes: _recordedVoiceBytes!,
          fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          mediaType: 'voice',
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      } else if (_recordedVoiceFile != null) {
        uploadResult = await _cloudinaryService.uploadAudio(
          audio: _recordedVoiceFile!,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      final voiceUrl = uploadResult?['secure_url'];
      if (voiceUrl == null || voiceUrl.isEmpty) {
        _setError('Failed to upload voice message');
        return false;
      }

      final publicId = uploadResult?['public_id'];
      final deleteToken = uploadResult?['delete_token'];

      await _databaseService.sendVoiceMessage(
        receiverId: receiverId,
        voiceUrl: voiceUrl,
        caption: caption,
        duration: _recordedVoiceDuration?.inSeconds.toDouble(),
        publicId: publicId,
        deleteToken: deleteToken,
      );

      await clearRecordedVoice(notify: false);
      _uploadProgress = 0.0;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send voice message');
      debugPrint('Error sending voice message: $e');
      return false;
    } finally {
      _isUploadingVoice = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}