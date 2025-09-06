/// Enhanced camera app that preserves ALL original functionality
/// This includes smile capture, face detection, privacy mode, harmoniser, performance optimization, etc.
/// PLUS adds new enhanced features like portrait mode, filters, advanced controls
library enhanced_camera_with_original_features;

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

// Import enhanced features
import 'camera_enhancements/camera_modes.dart';
import 'camera_enhancements/camera_controls.dart';
import 'camera_enhancements/camera_ui_enhancements.dart';
import 'camera_enhancements/image_processor.dart';

/// Enhanced camera that preserves all original features
class EnhancedCameraWithOriginalFeatures extends StatefulWidget {
  const EnhancedCameraWithOriginalFeatures({super.key});

  @override
  State<EnhancedCameraWithOriginalFeatures> createState() => _EnhancedCameraWithOriginalFeaturesState();
}

class _EnhancedCameraWithOriginalFeaturesState extends State<EnhancedCameraWithOriginalFeatures> 
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  // ===== ORIGINAL FEATURES - PRESERVED EXACTLY =====
  
  // Camera controller and basic state
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.off;
  bool _isInitialized = false;
  
  // Original UI features - PRESERVED
  bool _privacyMode = false;
  bool _harmoniser = false;
  bool _harmoniserMinimized = false;
  bool _privacyMinimized = false;
  String? _lastCapturedPath;
  VideoPlayerController? _videoPlayerController;
  
  // Face detection and smile capture - PRESERVED
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  int _countdown = 0;
  Timer? _timer;
  Timer? _processingTimer;
  int _photoIndex = 1;
  CameraImage? _latestImage;
  bool _isStreamingImages = false;
  
  // Performance optimization - PRESERVED
  bool _isOldDevice = false;
  Duration _processInterval = const Duration(milliseconds: 1500);
  static const Duration kOldDeviceInterval = Duration(milliseconds: 1500);
  static const Duration kNewDeviceInterval = Duration(milliseconds: 500);
  static const int MAX_FACES_TO_PROCESS = 6;
  bool _smileCaptureEnabled = true;

  // ===== NEW ENHANCED FEATURES =====
  
  // Enhanced mode and filter management
  late CameraModeManager _modeManager;
  CameraControlsManager? _controlsManager;
  
  // Enhanced UI state
  bool _showEnhancedControls = true;
  bool _showGrid = false;
  bool _isProcessingEnhanced = false;
  double _processingProgress = 0.0;
  String? _processingStatus;

  IconData _flashIconData() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize original features
    _detectDevicePerformance();
    _initializeCamera();
    
    // Initialize enhanced features
    _modeManager = CameraModeManager();
    
    // Initialize face detector (original feature)
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.3,
        performanceMode: FaceDetectorMode.fast,
      ),
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
    _modeManager.dispose();
    _controlsManager?.dispose();
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

  // ===== ORIGINAL METHODS - PRESERVED EXACTLY =====

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

        // Initialize enhanced controls
        _controlsManager = CameraControlsManager(_cameraController!);

        setState(() {
          _isInitialized = true;
        });

        await _startImageStreamIfNeeded();
        _startProcessingTimer();

        return;
        
      } catch (e) {
        _cameraController?.dispose();
        _cameraController = null;
      }
    }
    
    _showErrorDialog('Camera initialization failed with all image formats');
  }

  Future<void> _startImageStreamIfNeeded() async {
    if (_cameraController == null) return;
    if (_isStreamingImages) return;
    try {
      await _cameraController!.startImageStream((cameraImage) async {
        _latestImage = cameraImage;
      });
      _isStreamingImages = true;
    } catch (_) {
      // ignore if already streaming or not supported
    }
  }

  Future<void> _stopImageStreamIfActive() async {
    if (_cameraController == null) return;
    if (!_isStreamingImages) return;
    try {
      await _cameraController!.stopImageStream();
    } catch (_) {
      // ignore
    } finally {
      _isStreamingImages = false;
      _latestImage = null;
    }
  }

  void _startProcessingTimer() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(_processInterval, (timer) {
      if (_latestImage != null && !_isDetecting && _countdown == 0) {
        _processLatestImage();
      }
    });
  }

  void _stopProcessingTimer() {
    _processingTimer?.cancel();
    _processingTimer = null;
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
      // Handle error silently
    }

    _isDetecting = false;
  }

  InputImage? _createInputImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      
      InputImageRotation rotation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: _getInputImageFormat(image.format),
        bytesPerRow: image.planes[0].bytesPerRow,
      );

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
    if (_countdown > 0 || _photoIndex > 4) return;

    setState(() {
      _countdown = 3;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _countdown--;
      });

      if (_countdown == 0) {
        timer.cancel();
        await _capturePhoto();
        _photoIndex++;
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    _stopProcessingTimer();
    await _stopImageStreamIfActive();
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
      
      _processingTimer?.cancel();
      _processingTimer = Timer.periodic(_processInterval, (timer) {
        if (_latestImage != null && !_isDetecting && _countdown == 0) {
          _processLatestImage();
        }
      });
    });
    
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

  // ===== ENHANCED CAPTURE METHOD =====
  
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      
      // Enhanced processing if needed (modes or filters)
      File? finalFile;
      bool needsProcessing = _modeManager.requiresPostProcessing || _modeManager.currentFilter != FilterType.none;
      
      if (needsProcessing) {
        setState(() {
          _isProcessingEnhanced = true;
          _processingProgress = 0.0;
          _processingStatus = _modeManager.currentFilter != FilterType.none 
            ? 'Applying ${CameraFilters.getDisplayName(_modeManager.currentFilter)} filter...'
            : 'Processing ${_modeManager.currentModeDisplayName}...';
        });

        finalFile = await ImageProcessor.processImage(
          File(photo.path),
          _modeManager.currentMode,
          _modeManager.currentFilter,
          onProgress: (progress) {
            setState(() {
              _processingProgress = progress;
            });
          },
        );

        setState(() {
          _isProcessingEnhanced = false;
        });
      } else {
        finalFile = File(photo.path);
      }

      if (finalFile != null) {
        await Gal.putImage(finalFile.path);
        setState(() {
          _lastCapturedPath = finalFile!.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                needsProcessing 
                  ? _modeManager.currentFilter != FilterType.none
                    ? '${CameraFilters.getDisplayName(_modeManager.currentFilter)} filter applied and saved!'
                    : '${_modeManager.currentModeDisplayName} photo saved!'
                  : 'Photo saved to gallery!',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessingEnhanced = false;
      });
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

  void _handleShutterTap() {
    if (_isRecording) {
      _stopVideoRecording();
    } else if (_modeManager.currentMode == CameraMode.normal || 
               _modeManager.currentMode == CameraMode.portrait ||
               _modeManager.currentMode == CameraMode.hdr ||
               _modeManager.currentMode == CameraMode.night ||
               _modeManager.currentMode == CameraMode.filters) {
      _capturePhoto();
    } else {
      _startVideoRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Enhanced camera preview with effects
            Positioned.fill(
              child: _isInitialized && _cameraController != null
                  ? ListenableBuilder(
                      listenable: _modeManager,
                      builder: (context, child) {
                        return EnhancedCameraPreview(
                          cameraPreview: CameraPreview(_cameraController!),
                          modeManager: _modeManager,
                          showEffects: true,
                        );
                      },
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
            ),

            // Enhanced camera controls overlay
            if (_showEnhancedControls && _controlsManager != null)
              CameraControlsOverlay(
                controlsManager: _controlsManager!,
                showControls: _showEnhancedControls,
                onTapToFocus: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Focus set'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

            // Grid overlay
            if (_showGrid)
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(),
                ),
              ),

            // COUNTDOWN OVERLAY (original feature)
            if (_countdown > 0)
              Center(
                child: AnimatedScale(
                  scale: 1.2,
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

            // Top toolbar with original + enhanced features
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
                        _buildTopIconButton(Icons.settings, onTap: () {
                          setState(() {
                            _showEnhancedControls = !_showEnhancedControls;
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildTopIconButton(_flashIconData(), onTap: _toggleFlash),
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
                        _buildTopIconButton(
                          _showGrid ? Icons.grid_on : Icons.grid_off,
                          onTap: () {
                            setState(() {
                              _showGrid = !_showGrid;
                            });
                          },
                          color: _showGrid ? Colors.blue : Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        _buildTopIconButton(Icons.photo_size_select_actual, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),

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
                    // Original Harmoniser and Privacy controls (PRESERVED)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Harmoniser button (original feature)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final newVal = !_harmoniser;
                                _harmoniser = newVal;
                                if (newVal) {
                                  _privacyMode = false;
                                  _privacyMinimized = true;
                                  _harmoniserMinimized = false;
                                } else {
                                  _privacyMinimized = false;
                                  _harmoniserMinimized = false;
                                }
                              });
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
                                  Icon(
                                    Icons.tune,
                                    color: _harmoniser ? Colors.white : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: _harmoniserMinimized
                                        ? const SizedBox.shrink()
                                        : Text(
                                            'Harmoniser',
                                            style: TextStyle(color: _harmoniser ? Colors.white : Colors.white54),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Privacy button (original feature)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final newVal = !_privacyMode;
                                _privacyMode = newVal;
                                if (newVal) {
                                  _harmoniser = false;
                                  _harmoniserMinimized = true;
                                  _privacyMinimized = false;
                                } else {
                                  _harmoniserMinimized = false;
                                  _privacyMinimized = false;
                                }
                              });
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
                                  Icon(
                                    Icons.privacy_tip,
                                    color: _privacyMode ? Colors.white : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: _privacyMinimized
                                        ? const SizedBox.shrink()
                                        : Text(
                                            'Privacy',
                                            style: TextStyle(color: _privacyMode ? Colors.white : Colors.white54),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Enhanced mode selector
                    ListenableBuilder(
                      listenable: _modeManager,
                      builder: (context, child) {
                        return EnhancedModeSelector(
                          modeManager: _modeManager,
                          onModeChanged: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${_modeManager.currentModeDisplayName} mode activated'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Filter selector
                    ListenableBuilder(
                      listenable: _modeManager,
                      builder: (context, child) {
                        return FilterSelector(
                          modeManager: _modeManager,
                          onFilterChanged: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${_modeManager.currentFilterDisplayName} filter applied'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
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

                        // Enhanced shutter button
                        ListenableBuilder(
                          listenable: _modeManager,
                          builder: (context, child) {
                            return EnhancedShutterButton(
                              onTap: _handleShutterTap,
                              currentMode: _modeManager.currentMode,
                              isRecording: _isRecording,
                              isProcessing: _isProcessingEnhanced,
                            );
                          },
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

            // Processing overlay
            if (_isProcessingEnhanced)
              ProcessingOverlay(
                isVisible: _isProcessingEnhanced,
                progress: _processingProgress,
                statusText: _processingStatus,
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
}

/// Grid painter for rule of thirds
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Media preview screen
class MediaPreviewScreen extends StatefulWidget {
  final String filePath;

  const MediaPreviewScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _checkFileType();
  }

  void _checkFileType() {
    final extension = path.extension(widget.filePath).toLowerCase();
    _isVideo = extension == '.mp4' || extension == '.mov' || extension == '.avi';
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
            ? const Icon(Icons.play_circle_outline, color: Colors.white, size: 64)
            : Image.file(
                File(widget.filePath),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
