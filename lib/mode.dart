import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui';

// Import the enhanced camera features
import 'camera_enhancements/camera_modes.dart';
import 'camera_enhancements/camera_controls.dart';
import 'camera_enhancements/camera_ui_enhancements.dart';
import 'camera_enhancements/enhanced_camera.dart';
import 'enhanced_camera_with_original.dart'; // Complete implementation with all original features

class CameraModesApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraModesApp({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraModesApp> createState() => _CameraModesAppState();
}

class _CameraModesAppState extends State<CameraModesApp> {
  CameraController? _cameraController;
  
  // Enhanced features
  late CameraModeManager _modeManager;
  CameraControlsManager? _controlsManager;
  bool _useEnhancedVersion = true;

  @override
  void initState() {
    super.initState();
    _modeManager = CameraModeManager();
    
    if (!_useEnhancedVersion) {
      _initializeBasicCamera();
    }
  }

  Future<void> _initializeBasicCamera() async {
    if (widget.cameras.isNotEmpty) {
      _cameraController = CameraController(
        widget.cameras.first,
        ResolutionPreset.high,
      );

      try {
        await _cameraController!.initialize();
        _controlsManager = CameraControlsManager(_cameraController!);
        setState(() {});
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    }
  }

  @override
  void dispose() {
    _modeManager.dispose();
    _controlsManager?.dispose();
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Camera Modes'),
        actions: [
          // Toggle between enhanced and basic version
          IconButton(
            icon: Icon(_useEnhancedVersion ? Icons.camera_enhance : Icons.camera_alt),
            onPressed: () {
              setState(() {
                _useEnhancedVersion = !_useEnhancedVersion;
              });
              if (!_useEnhancedVersion && _cameraController == null) {
                _initializeBasicCamera();
              }
            },
          ),
        ],
      ),
      body: _useEnhancedVersion 
          ? _buildEnhancedCamera()
          : _buildBasicCameraWithEnhancements(),
    );
  }

  /// Option 1: Use the complete enhanced camera (recommended)
  Widget _buildEnhancedCamera() {
    return EnhancedCameraApp(
      cameras: widget.cameras,
      enableSmileCapture: true,
      enableEnhancedFeatures: true,
    );
  }

  /// Option 2: Your existing camera with selective enhancements
  Widget _buildBasicCameraWithEnhancements() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Your existing camera preview with enhanced effects
        Positioned.fill(
          child: ListenableBuilder(
            listenable: _modeManager,
            builder: (context, child) {
              return EnhancedCameraPreview(
                cameraPreview: CameraPreview(_cameraController!),
                modeManager: _modeManager,
                showEffects: true,
              );
            },
          ),
        ),

        // Enhanced camera controls overlay
        if (_controlsManager != null)
          CameraControlsOverlay(
            controlsManager: _controlsManager!,
            showControls: true,
            onTapToFocus: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Focus set'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

        // Bottom enhanced controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced mode selector (replaces your basic toggle)
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

                // Filter selector (shows when filters mode is active)
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

                const SizedBox(height: 16),

                // Enhanced shutter button
                ListenableBuilder(
                  listenable: _modeManager,
                  builder: (context, child) {
                    return EnhancedShutterButton(
                      onTap: () => _capturePhoto(),
                      currentMode: _modeManager.currentMode,
                      isRecording: false,
                      isProcessing: false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_modeManager.currentModeDisplayName} photo captured!'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      debugPrint('Photo saved: ${photo.path}');
      debugPrint('Current mode: ${_modeManager.currentMode}');
      debugPrint('Current filter: ${_modeManager.currentFilter}');
      
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(
    home: CameraModesApp(cameras: cameras),
    theme: ThemeData.dark(),
  ));
}