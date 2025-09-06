/// Enhanced camera implementation that extends your existing camera app
/// This provides a drop-in replacement with all new features
library enhanced_camera;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';

// Import our enhancement modules
import 'camera_modes.dart';
import 'camera_controls.dart';
import 'image_processor.dart';
import 'camera_ui_enhancements.dart';

/// Enhanced camera app that extends existing functionality
class EnhancedCameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool enableSmileCapture;
  final bool enableEnhancedFeatures;

  const EnhancedCameraApp({
    Key? key,
    required this.cameras,
    this.enableSmileCapture = true,
    this.enableEnhancedFeatures = true,
  }) : super(key: key);

  @override
  State<EnhancedCameraApp> createState() => _EnhancedCameraAppState();
}

class _EnhancedCameraAppState extends State<EnhancedCameraApp> 
    with WidgetsBindingObserver {
  
  // Camera controller
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  
  // Enhanced features managers
  late CameraModeManager _modeManager;
  CameraControlsManager? _controlsManager;
  
  // Camera state
  FlashMode _flashMode = FlashMode.off;
  bool _isRecording = false;
  String? _lastCapturedPath;
  
  // UI state
  bool _showControls = true;
  bool _showGrid = false;
  bool _timerEnabled = false;
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String? _processingStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize managers
    _modeManager = CameraModeManager();
    
    // Initialize camera
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _controlsManager?.dispose();
    _modeManager.dispose();
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
    if (widget.cameras.isEmpty) return;

    try {
      _cameraController = CameraController(
        widget.cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);

      // Initialize enhanced controls
      _controlsManager = CameraControlsManager(_cameraController!);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _showErrorDialog('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    await _cameraController?.dispose();
    _controlsManager?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    await _initializeCamera();
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
      
      // Process image if needed
      File? finalFile;
      if (widget.enableEnhancedFeatures && _modeManager.requiresPostProcessing) {
        setState(() {
          _isProcessing = true;
          _processingProgress = 0.0;
          _processingStatus = 'Processing ${_modeManager.currentModeDisplayName}...';
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
          _isProcessing = false;
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
                _modeManager.requiresPostProcessing 
                  ? '${_modeManager.currentModeDisplayName} photo saved!'
                  : 'Photo saved to gallery!',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
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

  void _showLastCaptured() {
    if (_lastCapturedPath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPreviewScreen(filePath: _lastCapturedPath!),
      ),
    );
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

  IconData _getFlashIcon() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview with effects
            Positioned.fill(
              child: _isInitialized && _cameraController != null
                  ? widget.enableEnhancedFeatures
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
                      : CameraPreview(_cameraController!)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
            ),

            // Enhanced camera controls overlay
            if (widget.enableEnhancedFeatures && _controlsManager != null)
              CameraControlsOverlay(
                controlsManager: _controlsManager!,
                showControls: _showControls,
                onTapToFocus: () {
                  // Show focus indicator
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
                        _buildTopIconButton(Icons.settings, onTap: () {
                          setState(() {
                            _showControls = !_showControls;
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildTopIconButton(_getFlashIcon(), onTap: _toggleFlash),
                        const SizedBox(width: 8),
                        _buildTopIconButton(
                          _timerEnabled ? Icons.timer : Icons.timer_off,
                          onTap: () {
                            setState(() {
                              _timerEnabled = !_timerEnabled;
                            });
                          },
                          color: _timerEnabled ? Colors.orange : Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        _buildTopIconButton(
                          _showGrid ? Icons.grid_on : Icons.grid_off,
                          onTap: () {
                            setState(() {
                              _showGrid = !_showGrid;
                            });
                          },
                          color: _showGrid ? Colors.blue : Colors.white70,
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
                    // Enhanced mode selector
                    if (widget.enableEnhancedFeatures)
                      ListenableBuilder(
                        listenable: _modeManager,
                        builder: (context, child) {
                          return EnhancedModeSelector(
                            modeManager: _modeManager,
                            onModeChanged: () {
                              // Optional: Add haptic feedback or sound
                            },
                          );
                        },
                      ),

                    // Filter selector (shows when filters mode is active)
                    if (widget.enableEnhancedFeatures)
                      ListenableBuilder(
                        listenable: _modeManager,
                        builder: (context, child) {
                          return FilterSelector(
                            modeManager: _modeManager,
                            onFilterChanged: () {
                              // Optional: Add haptic feedback
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
                        if (widget.enableEnhancedFeatures)
                          ListenableBuilder(
                            listenable: _modeManager,
                            builder: (context, child) {
                              return EnhancedShutterButton(
                                onTap: _handleShutterTap,
                                currentMode: _modeManager.currentMode,
                                isRecording: _isRecording,
                                isProcessing: _isProcessing,
                              );
                            },
                          )
                        else
                          // Fallback to basic shutter
                          GestureDetector(
                            onTap: _handleShutterTap,
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white70, width: 3),
                              ),
                              child: Center(
                                child: Icon(
                                  _isRecording ? Icons.stop : Icons.camera_alt,
                                  color: _isRecording ? Colors.white : Colors.black,
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

            // Processing overlay
            if (_isProcessing)
              ProcessingOverlay(
                isVisible: _isProcessing,
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
