import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart'; 


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
  String? _lastCapturedPath;
  VideoPlayerController? _videoPlayerController;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  int _countdown = 0;
  Timer? _timer;
  Timer? _processingTimer;
  int _photoIndex = 1;
  CameraImage? _latestImage;
  
  bool _isOldDevice = false;
  Duration _processInterval = const Duration(milliseconds: 1500);
  static const Duration kOldDeviceInterval = Duration(milliseconds: 1500);
  static const Duration kNewDeviceInterval = Duration(milliseconds: 500);
  
  static const int MAX_FACES_TO_PROCESS = 6;

  bool _smileCaptureEnabled = true;


  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _detectDevicePerformance();
  _initializeCamera();
  
  _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // Keep smile detection
      enableLandmarks: false,     // Disable to save processing
      enableContours: false,      // Disable to save processing
      enableTracking: false,      // Disable to save processing
      minFaceSize: 0.3,          // Only detect larger faces (less processing)
      performanceMode: FaceDetectorMode.fast, // Use fast mode for older devices
    ),
  );
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _cameraController?.dispose();
  _videoPlayerController?.dispose();
  _faceDetector.close(); // Dispose ML Kit face detector
  _timer?.cancel();      // Cancel any active countdown
  _processingTimer?.cancel(); // Cancel processing timer
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

  void _detectDevicePerformance() {
    if (Platform.isAndroid) {
      try {
        _isOldDevice = _isLikelyOldDevice();
        _processInterval = _isOldDevice ? kOldDeviceInterval : kNewDeviceInterval;
        
        print('Device performance detected: ${_isOldDevice ? "Old" : "New"} device');
        print('Processing interval set to: ${_processInterval.inMilliseconds}ms');
      } catch (e) {
        _isOldDevice = true;
        _processInterval = kOldDeviceInterval;
        print('Device detection failed, using conservative settings: $e');
      }
    } else {
      _isOldDevice = false;
      _processInterval = kNewDeviceInterval;
    }
  }

  bool _isLikelyOldDevice() {
    final stopwatch = Stopwatch()..start();
    var result = 0;
    for (int i = 0; i < 100000; i++) {
      result += i * 2;
    }
    stopwatch.stop();
    if (result < 0) print('Unexpected result');
    return stopwatch.elapsedMilliseconds > 5;
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

  final formats = [ImageFormatGroup.nv21, ImageFormatGroup.yuv420];
  
  for (final format in formats) {
    try {
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: format,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);

      setState(() {
        _isInitialized = true;
      });

      _cameraController?.startImageStream((cameraImage) async {
        _latestImage = cameraImage;
      });

      _processingTimer = Timer.periodic(_processInterval, (timer) {
        if (_latestImage != null && !_isDetecting && _countdown == 0) {
          _processLatestImage();
        }
      });

      return;
      
    } catch (e) {
      _cameraController?.dispose();
      _cameraController = null;
    }
  }
  
  // If we get here, all formats failed
  _showErrorDialog('Camera initialization failed with all image formats');
}

  Future<void> _processLatestImage() async {
  if (_latestImage == null || _isDetecting || !_smileCaptureEnabled) return;

    _isDetecting = true;

    try {
      final inputImage = _createInputImage(_latestImage!);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final limitedFaces = faces.take(MAX_FACES_TO_PROCESS).toList();
          
          int smilingCount = limitedFaces
              .where((face) => face.smilingProbability != null && face.smilingProbability! >= 0.2)
              .length;

          if (smilingCount / limitedFaces.length >= 0.5) {
            _startCountdown();
          }
        }
      }
    } catch (e) {
    }

    _isDetecting = false;
  }

  InputImage? _createInputImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      
      // Determine rotation based on camera
      InputImageRotation rotation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }

      // Create input image metadata
      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: _getInputImageFormat(image.format),
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      // Create InputImage from camera image
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      return null;
    }
  }

  InputImageFormat _getInputImageFormat(ImageFormat format) {
    switch (format.group) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      default:
        return InputImageFormat.yuv420;
    }
  }


  void _startCountdown() {
  if (_countdown > 0 || _photoIndex > 4) return; // max 4 photos

  setState(() {
    _countdown = 3; // 3-second timer
  });

  _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    setState(() {
      _countdown--;
    });

    if (_countdown == 0) {
      timer.cancel();
      await _capturePhoto(); // capture the photo when countdown ends
      _photoIndex++;         // increment photo counter
    }
  });
}

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    // Stop processing timer and image stream
    _processingTimer?.cancel();
    await _cameraController?.stopImageStream().catchError((_) {});
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

  void _togglePerformanceMode() {
    setState(() {
      _isOldDevice = !_isOldDevice;
      _processInterval = _isOldDevice ? kOldDeviceInterval : kNewDeviceInterval;
      
      // Restart the processing timer with new interval
      _processingTimer?.cancel();
      _processingTimer = Timer.periodic(_processInterval, (timer) {
        if (_latestImage != null && !_isDetecting && _countdown == 0) {
          _processLatestImage();
        }
      });
    });
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOldDevice 
            ? 'Performance Mode: Old Device (${kOldDeviceInterval.inMilliseconds}ms)' 
            : 'Performance Mode: New Device (${kNewDeviceInterval.inMilliseconds}ms)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _isOldDevice ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
            // COUNTDOWN OVERLAY
            if (_countdown > 0)
              Center(
                child: AnimatedScale(
                  scale: 1.2, // initial scale
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 72,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
            // Top toolbar with smile capture toggle
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
                        const SizedBox(width: 8),
                        _buildTopIconButton(
                          _isOldDevice ? Icons.speed : Icons.speed_outlined, 
                          onTap: _togglePerformanceMode
                        ),
                        const SizedBox(width: 16),
                        _buildTopIconButton(
                          _smileCaptureEnabled ? Icons.emoji_emotions : Icons.emoji_emotions_outlined,
                          onTap: () {
                            setState(() {
                              _smileCaptureEnabled = !_smileCaptureEnabled;
                            });
                          },
                          color: _smileCaptureEnabled ? Colors.yellow : Colors.white,
                        ),
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

  Widget _buildTopIconButton(IconData icon, {required VoidCallback onTap, Color color = Colors.white70}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
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
