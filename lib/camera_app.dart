
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
import 'package:vosk_flutter/vosk_flutter.dart';

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with WidgetsBindingObserver {
  // Static constants
  static const Duration kOldDeviceInterval = Duration(milliseconds: 1500);
  static const Duration kNewDeviceInterval = Duration(milliseconds: 500);
  static const int MAX_FACES_TO_PROCESS = 6;

  // Vosk speech recognition
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin();
  Model? _model;
  SpeechService? _speechService;
  StreamSubscription? _resultSubscription;
  bool _isListening = false;
  String _lastVoiceCommand = '';

  // Camera and state variables
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
  Duration _processInterval = kNewDeviceInterval;

  bool _smileCaptureEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _detectDevicePerformance();
    _initializeCamera();
    _initVosk();
  }

  Future<void> _initVosk() async {
    try {
      _model = await _vosk.createModel('assets/vosk_models/vosk-model-small-en-us-0.15');
      _speechService = await _vosk.createSpeechService(_model!);

      _resultSubscription = _speechService!.onResults().listen((result) {
        final text = result.text;
        if (text != null && text.isNotEmpty) {
          setState(() {
            _lastVoiceCommand = text;
          });
          _handleVoiceCommand(text);
        }
      });

       _speechService!.onListeningStateChanged().listen((isListening) {
        if (mounted) {
          setState(() => _isListening = isListening);
        }
      });

    } catch (e) {
      print('Vosk init error: $e');
    }
  }

  void _toggleListening() async {
    if (_speechService == null) return;
    try {
      if (_isListening) {
        await _speechService!.stop();
      } else {
        await _speechService!.start();
      }
    } catch (e) {
      print("Error toggling listening: $e");
    }
  }

  void _handleVoiceCommand(String command) {
    final cmd = command.toLowerCase();
    if (cmd.contains('photo') || cmd.contains('capture')) {
      _capturePhoto();
    } else if (cmd.contains('video') && cmd.contains('start')) {
      _startVideoRecording();
    } else if (cmd.contains('video') && cmd.contains('stop')) {
      _stopVideoRecording();
    } else if (cmd.contains('switch')) {
      _switchCamera();
    } else if (cmd.contains('smile')) {
      setState(() => _smileCaptureEnabled = !_smileCaptureEnabled);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice: $command')),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _faceDetector.close();
    _timer?.cancel();
    _processingTimer?.cancel();
    _resultSubscription?.cancel();
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
    // Simplified: logic can be re-added if necessary
    _processInterval = kNewDeviceInterval;
  }

  Future<void> _initializeCamera() async {
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

    final controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      controller.startImageStream((cameraImage) {
        _latestImage = cameraImage;
      });

      _processingTimer = Timer.periodic(_processInterval, (_) {
        if (_latestImage != null && !_isDetecting && _countdown == 0) {
          _processLatestImage();
        }
      });
      
      setState(() {
        _cameraController = controller;
        _isInitialized = true;
      });

    } catch (e) {
      controller.dispose();
      _showErrorDialog('Camera initialization failed: $e');
    }
  }

  Future<void> _processLatestImage() async {
    if (_latestImage == null || !_isDetecting || !_smileCaptureEnabled) return;
    _isDetecting = true;

    try {
      final inputImage = _createInputImage(_latestImage!);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final smilingCount = faces
              .where((f) => (f.smilingProbability ?? 0) > 0.2)
              .length;
          if (smilingCount / faces.length >= 0.5) {
            _startCountdown();
          }
        }
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _createInputImage(CameraImage image) {
    final camera = _cameras[_selectedCameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _startCountdown() {
    if (_countdown > 0 || _photoIndex > 4) return;
    setState(() => _countdown = 3);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        _capturePhoto();
        setState(() => _countdown = 0);
        _photoIndex++;
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitialized = false);
    _processingTimer?.cancel();
    await _cameraController?.dispose();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      _showErrorDialog('Error changing flash mode: $e');
    }
  }

  void _togglePerformanceMode() {
    setState(() {
      _isOldDevice = !_isOldDevice;
      _processInterval = _isOldDevice ? kOldDeviceInterval : kNewDeviceInterval;
      _processingTimer?.cancel();
      _processingTimer = Timer.periodic(_processInterval, (_) {
         if (_latestImage != null && !_isDetecting && _countdown == 0) {
          _processLatestImage();
        }
      });
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final photo = await _cameraController!.takePicture();
      await Gal.putImage(photo.path);
      setState(() => _lastCapturedPath = photo.path);
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      _showErrorDialog('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;
    try {
      final video = await _cameraController!.stopVideoRecording();
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
    if (!mounted) return;
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
            if (_isInitialized && _cameraController != null)
              Positioned.fill(child: CameraPreview(_cameraController!))
            else
              const Center(child: CircularProgressIndicator()),
            
            if (_countdown > 0)
              Center(
                child: Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 96))
              ),

            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                   IconButton(
                    icon: Icon(_flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                    onPressed: _toggleFlash,
                  ),
                  IconButton(
                    icon: Icon(_smileCaptureEnabled ? Icons.emoji_emotions : Icons.emoji_emotions_outlined, color: _smileCaptureEnabled ? Colors.yellow : Colors.white),
                    onPressed: () => setState(() => _smileCaptureEnabled = !_smileCaptureEnabled),
                  ),
                ],
              )
            ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black26,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Thumbnail
                        GestureDetector(
                          onTap: _showLastCaptured,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.white),
                              image: _lastCapturedPath != null ? DecorationImage(
                                image: FileImage(File(_lastCapturedPath!)),
                                fit: BoxFit.cover,
                              ) : null,
                            ),
                            child: _lastCapturedPath == null ? const Icon(Icons.photo_library, color: Colors.white) : null,
                          ),
                        ),
                        // Shutter
                        GestureDetector(
                          onTap: _isPhotoMode ? _capturePhoto : (_isRecording ? _stopVideoRecording : _startVideoRecording),
                          child: Icon(_isPhotoMode ? Icons.camera_alt : Icons.videocam, color: _isRecording ? Colors.red : Colors.white, size: 72),
                        ),
                        // Switch Camera
                        IconButton(
                          icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 36),
                          onPressed: _switchCamera,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Voice Command
                    FloatingActionButton(
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      onPressed: _toggleListening,
                      child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                    ),
                    if (_lastVoiceCommand.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_lastVoiceCommand, style: const TextStyle(color: Colors.white)),
                      )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
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
  bool get _isVideo => path.extension(widget.filePath) == '.mp4';

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _videoPlayerController = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) => setState(() {}))
        ..setLooping(true);
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
      body: Center(
        child: _isVideo
            ? (_videoPlayerController?.value.isInitialized ?? false)
                ? AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoPlayerController!.value.isPlaying
                            ? _videoPlayerController!.pause()
                            : _videoPlayerController!.play();
                        });
                      },
                      child: VideoPlayer(_videoPlayerController!)
                    ),
                  )
                : const CircularProgressIndicator()
            : Image.file(File(widget.filePath)),
      ),
    );
  }
}

