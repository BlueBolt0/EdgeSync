/// Integration example showing how to use the enhanced camera features
/// with your existing camera implementation
library integration_example;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Import the enhancement modules
import 'camera_enhancements/camera_modes.dart';
import 'camera_enhancements/camera_controls.dart';
import 'camera_enhancements/camera_ui_enhancements.dart';
import 'camera_enhancements/enhanced_camera.dart';

/// Example of how to integrate enhancements into your existing CameraApp
class IntegratedCameraExample extends StatefulWidget {
  final List<CameraDescription> cameras;

  const IntegratedCameraExample({Key? key, required this.cameras}) : super(key: key);

  @override
  State<IntegratedCameraExample> createState() => _IntegratedCameraExampleState();
}

class _IntegratedCameraExampleState extends State<IntegratedCameraExample> {
  // Option 1: Use the complete enhanced camera
  bool _useEnhancedCamera = true;

  // Option 2: Individual enhancement components
  late CameraModeManager _modeManager;
  CameraController? _cameraController;
  CameraControlsManager? _controlsManager;

  @override
  void initState() {
    super.initState();
    _modeManager = CameraModeManager();
    
    if (!_useEnhancedCamera) {
      _initializeBasicCamera();
    }
  }

  @override
  void dispose() {
    _modeManager.dispose();
    _cameraController?.dispose();
    _controlsManager?.dispose();
    super.dispose();
  }

  Future<void> _initializeBasicCamera() async {
    if (widget.cameras.isEmpty) return;

    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
    _controlsManager = CameraControlsManager(_cameraController!);
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Camera Integration'),
        actions: [
          IconButton(
            icon: Icon(_useEnhancedCamera ? Icons.camera : Icons.camera_alt),
            onPressed: () {
              setState(() {
                _useEnhancedCamera = !_useEnhancedCamera;
              });
            },
          ),
        ],
      ),
      body: _useEnhancedCamera
          ? _buildCompleteEnhancedCamera()
          : _buildSelectiveEnhancements(),
    );
  }

  /// Option 1: Use the complete enhanced camera (recommended)
  Widget _buildCompleteEnhancedCamera() {
    return EnhancedCameraApp(
      cameras: widget.cameras,
      enableSmileCapture: true,
      enableEnhancedFeatures: true,
    );
  }

  /// Option 2: Selective integration of enhancement components
  Widget _buildSelectiveEnhancements() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Your existing camera preview
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

        // Add enhanced controls overlay
        if (_controlsManager != null)
          CameraControlsOverlay(
            controlsManager: _controlsManager!,
            showControls: true,
          ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced mode selector
                ListenableBuilder(
                  listenable: _modeManager,
                  builder: (context, child) {
                    return EnhancedModeSelector(
                      modeManager: _modeManager,
                      onModeChanged: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_modeManager.currentModeDisplayName} mode selected'),
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

                const SizedBox(height: 16),

                // Enhanced shutter button
                ListenableBuilder(
                  listenable: _modeManager,
                  builder: (context, child) {
                    return EnhancedShutterButton(
                      onTap: _capturePhoto,
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
    // Your existing photo capture logic here
    // You can integrate with ImageProcessor for post-processing
    
    try {
      final XFile photo = await _cameraController!.takePicture();
      
      // Save the photo or process it further
      debugPrint('Photo captured: ${photo.path}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_modeManager.currentModeDisplayName} photo captured!'),
        ),
      );
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }
}

/// How to integrate enhancements into your existing camera_app.dart
/// 
/// 1. Add these imports to your existing camera_app.dart:
/// ```dart
/// import 'camera_enhancements/camera_modes.dart';
/// import 'camera_enhancements/camera_controls.dart';
/// import 'camera_enhancements/camera_ui_enhancements.dart';
/// import 'camera_enhancements/image_processor.dart';
/// ```
/// 
/// 2. Add these fields to your _CameraAppState class:
/// ```dart
/// late CameraModeManager _modeManager;
/// CameraControlsManager? _controlsManager;
/// bool _isProcessing = false;
/// double _processingProgress = 0.0;
/// ```
/// 
/// 3. Initialize in initState():
/// ```dart
/// _modeManager = CameraModeManager();
/// ```
/// 
/// 4. Initialize controls manager after camera setup:
/// ```dart
/// _controlsManager = CameraControlsManager(_cameraController!);
/// ```
/// 
/// 5. Replace your mode buttons with:
/// ```dart
/// ListenableBuilder(
///   listenable: _modeManager,
///   builder: (context, child) {
///     return EnhancedModeSelector(
///       modeManager: _modeManager,
///       onModeChanged: () {
///         // Your existing mode change logic
///       },
///     );
///   },
/// ),
/// ```
/// 
/// 6. Add enhanced controls overlay to your Stack:
/// ```dart
/// if (_controlsManager != null)
///   CameraControlsOverlay(
///     controlsManager: _controlsManager!,
///     showControls: true,
///   ),
/// ```
/// 
/// 7. Update your _capturePhoto method:
/// ```dart
/// Future<void> _capturePhoto() async {
///   if (_cameraController == null || !_cameraController!.value.isInitialized) {
///     return;
///   }
/// 
///   try {
///     final XFile photo = await _cameraController!.takePicture();
///     
///     // Process image if needed
///     File? finalFile;
///     if (_modeManager.requiresPostProcessing) {
///       setState(() {
///         _isProcessing = true;
///         _processingProgress = 0.0;
///       });
/// 
///       finalFile = await ImageProcessor.processImage(
///         File(photo.path),
///         _modeManager.currentMode,
///         _modeManager.currentFilter,
///         onProgress: (progress) {
///           setState(() {
///             _processingProgress = progress;
///           });
///         },
///       );
/// 
///       setState(() {
///         _isProcessing = false;
///       });
///     } else {
///       finalFile = File(photo.path);
///     }
/// 
///     if (finalFile != null) {
///       await Gal.putImage(finalFile.path);
///       setState(() {
///         _lastCapturedPath = finalFile!.path;
///       });
///     }
///   } catch (e) {
///     _showErrorDialog('Error capturing photo: $e');
///   }
/// }
/// ```
/// 
/// 8. Add processing overlay to your Stack:
/// ```dart
/// if (_isProcessing)
///   ProcessingOverlay(
///     isVisible: _isProcessing,
///     progress: _processingProgress,
///     statusText: 'Processing ${_modeManager.currentModeDisplayName}...',
///   ),
/// ```
/// 
/// 9. Don't forget to dispose in dispose():
/// ```dart
/// _modeManager.dispose();
/// _controlsManager?.dispose();
/// ```

/// Example of a minimal integration that just adds mode management
class MinimalIntegrationExample extends StatefulWidget {
  const MinimalIntegrationExample({Key? key}) : super(key: key);

  @override
  State<MinimalIntegrationExample> createState() => _MinimalIntegrationExampleState();
}

class _MinimalIntegrationExampleState extends State<MinimalIntegrationExample> {
  late CameraModeManager _modeManager;

  @override
  void initState() {
    super.initState();
    _modeManager = CameraModeManager();
  }

  @override
  void dispose() {
    _modeManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Integration')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Your Camera Preview Here',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          
          // Just add the enhanced mode selector
          Container(
            color: Colors.black87,
            child: ListenableBuilder(
              listenable: _modeManager,
              builder: (context, child) {
                return EnhancedModeSelector(
                  modeManager: _modeManager,
                  onModeChanged: () {
                    print('Mode changed to: ${_modeManager.currentMode}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
