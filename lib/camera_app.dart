import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'package:video_player/video_player.dart';

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _isPhotoMode = true;
  FlashMode _flashMode = FlashMode.off;
  bool _isInitialized = false;
  bool _privacyMode = false;
  bool _harmoniser = false;
  String? _lastCapturedPath;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Request camera permissions
    final cameraPermission = await Permission.camera.request();
    final microphonePermission = await Permission.microphone.request();

    if (cameraPermission.isGranted && microphonePermission.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          await _setupCameraController();
        }
      } catch (e) {
        _showErrorDialog('Error initializing camera: $e');
      }
    } else {
      _showErrorDialog('Camera and microphone permissions are required');
    }
  }

  Future<void> _setupCameraController() async {
    if (_cameras.isEmpty) return;

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showErrorDialog('Error setting up camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    await _cameraController?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    FlashMode newFlashMode;
    switch (_flashMode) {
      case FlashMode.off:
        newFlashMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newFlashMode = FlashMode.always;
        break;
      case FlashMode.always:
        newFlashMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newFlashMode = FlashMode.off;
        break;
    }

    try {
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _flashMode = newFlashMode;
      });
    } catch (e) {
      _showErrorDialog('Error changing flash mode: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      await Gal.putImage(photo.path);
      
      setState(() {
        _lastCapturedPath = photo.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved to gallery!')),
        );
      }
    } catch (e) {
      _showErrorDialog('Error capturing photo: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showErrorDialog('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      await Gal.putVideo(video.path);
      
      setState(() {
        _isRecording = false;
        _lastCapturedPath = video.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved to gallery!')),
        );
      }
    } catch (e) {
      _showErrorDialog('Error stopping video recording: $e');
    }
  }

  void _toggleMode() {
    setState(() {
      _isPhotoMode = !_isPhotoMode;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLastCaptured() {
    if (_lastCapturedPath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPreviewScreen(filePath: _lastCapturedPath!),
      ),
    );
  }

  String _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return '💡';
      case FlashMode.auto:
        return '⚡';
      case FlashMode.always:
        return '🔆';
      case FlashMode.torch:
        return '🔦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview (fills available space)
            Positioned.fill(
              child: _isInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
            ),

            // Top toolbar
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildTopIconButton(Icons.settings, onTap: () {}),
                        const SizedBox(width: 8),
                        _buildTopIconButton(Icons.flash_on, onTap: _toggleFlash),
                        const SizedBox(width: 8),
                        _buildTopIconButton(Icons.timer, onTap: () {}),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTopIconButton(Icons.crop_7_5, onTap: () {}),
                        const SizedBox(width: 8),
                        _buildTopIconButton(Icons.photo_size_select_actual, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // (center hint removed as requested)

            // Bottom control panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Control buttons row: Harmoniser (left) and Privacy (right)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Harmoniser button (left)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _harmoniser = !_harmoniser;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_harmoniser ? 'Harmoniser ON' : 'Harmoniser OFF')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _harmoniser ? Colors.teal : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ImageIcon(
                                    AssetImage('assets/icons/harmonizer.png'),
                                    color: _harmoniser ? Colors.white : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Harmoniser',
                                    style: TextStyle(color: _harmoniser ? Colors.white : Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Privacy button (right)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _privacyMode = !_privacyMode;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_privacyMode ? 'Privacy Mode ON' : 'Privacy Mode OFF')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _privacyMode ? Colors.deepPurple : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ImageIcon(
                                    AssetImage('assets/icons/privacy.png'),
                                    color: _privacyMode ? Colors.white : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Privacy',
                                    style: TextStyle(color: _privacyMode ? Colors.white : Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mode labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModeLabel('PORTRAIT', false),
                        const SizedBox(width: 12),
                        _buildModeLabel('PHOTO', _isPhotoMode),
                        const SizedBox(width: 12),
                        _buildModeLabel('VIDEO', !_isPhotoMode),
                        const SizedBox(width: 12),
                        _buildModeLabel('MORE', false),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Last captured thumbnail
                        GestureDetector(
                          onTap: _showLastCaptured,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: _lastCapturedPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_lastCapturedPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.photo_library, color: Colors.white54),
                          ),
                        ),

                        // Shutter
                        GestureDetector(
                          onTap: _isPhotoMode
                              ? _capturePhoto
                              : _isRecording
                                  ? _stopVideoRecording
                                  : _startVideoRecording,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: _isPhotoMode ? Colors.white : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 3),
                            ),
                            child: Center(
                              child: _isRecording
                                  ? const Icon(Icons.stop, color: Colors.white, size: 30)
                                  : Icon(
                                      _isPhotoMode ? Icons.camera_alt : Icons.videocam,
                                      color: _isPhotoMode ? Colors.black : Colors.white,
                                      size: 30,
                                    ),
                            ),
                          ),
                        ),

                        // Switch camera
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cameraswitch, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildModeLabel(String text, bool selected) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        color: selected ? Colors.white : Colors.white54,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: 1.2,
      ),
      child: Text(text),
    );
  }
}

class MediaPreviewScreen extends StatefulWidget {
  final String filePath;

  const MediaPreviewScreen({super.key, required this.filePath});

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _videoPlayerController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _checkFileType();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _checkFileType() {
    final extension = path.extension(widget.filePath).toLowerCase();
    _isVideo = extension == '.mp4' || extension == '.mov' || extension == '.avi';
    
    if (_isVideo) {
      _videoPlayerController = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isVideo ? 'Video Preview' : 'Photo Preview',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _isVideo
            ? _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _videoPlayerController!.value.isPlaying
                                    ? _videoPlayerController!.pause()
                                    : _videoPlayerController!.play();
                              });
                            },
                            icon: Icon(
                              _videoPlayerController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const CircularProgressIndicator()
            : Image.file(
                File(widget.filePath),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
