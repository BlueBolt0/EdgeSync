import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() => runApp(OptimizedFaceApp());

class OptimizedFaceApp extends StatelessWidget {
  const OptimizedFaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optimized Face Detection',
      home: OptimizedFaceScreen(),
    );
  }
}

class OptimizedFaceScreen extends StatefulWidget {
  const OptimizedFaceScreen({super.key});

  @override
  _OptimizedFaceScreenState createState() => _OptimizedFaceScreenState();
}

class _OptimizedFaceScreenState extends State<OptimizedFaceScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  String _status = 'Initializing...';
  String _faceInfo = 'No faces detected';
  int _cameraIndex = 0;
  Timer? _processingTimer;
  CameraImage? _latestImage;
  
  // Performance optimization: Reduce processing frequency
  static const Duration PROCESSING_INTERVAL = Duration(milliseconds: 500); // Process every 500ms instead of every frame
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initializeFaceDetector();
    await _initializeCamera();
    _startPeriodicProcessing();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() => _status = '❌ Camera permission denied');
      return;
    }
    setState(() => _status = '✅ Camera permission granted');
  }

  Future<void> _initializeFaceDetector() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // For smile detection
          enableLandmarks: false,     // Disable to save processing
          enableContours: false,      // Disable to save processing
          enableTracking: false,      // Disable to save processing
        ),
      );
      setState(() => _status = '✅ Face detector initialized');
    } catch (e) {
      setState(() => _status = '❌ Face detector failed: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = '❌ No cameras available');
        return;
      }

      // Try different image formats for compatibility
      final formats = [ImageFormatGroup.nv21, ImageFormatGroup.yuv420];
      
      for (final format in formats) {
        try {
          print('📷 Trying image format: $format');
          
          _controller = CameraController(
            cameras[_cameraIndex],
            ResolutionPreset.medium, // Use medium instead of high for better performance
            imageFormatGroup: format,
          );

          await _controller!.initialize();
          
          if (mounted) {
            setState(() {
              _status = '✅ Camera initialized with format $format';
            });
          }
          
          print('✅ Camera initialized with format $format');
          return; // Success, exit the loop
          
        } catch (e) {
          print('❌ Failed with format $format: $e');
          _controller?.dispose();
          _controller = null;
        }
      }
      
      // If we get here, all formats failed
      setState(() => _status = '❌ All camera formats failed');
      
    } catch (e) {
      setState(() => _status = '❌ Camera initialization failed: $e');
    }
  }

  void _startPeriodicProcessing() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.startImageStream((CameraImage image) {
        // Store the latest image instead of processing immediately
        _latestImage = image;
      });

      // Process images at reduced frequency
      _processingTimer = Timer.periodic(PROCESSING_INTERVAL, (timer) {
        if (_latestImage != null && !_isDetecting) {
          _processLatestImage();
        }
      });
    }
  }

  Future<void> _processLatestImage() async {
    if (_latestImage == null || _isDetecting || _faceDetector == null) return;

    _isDetecting = true;
    
    try {
      final inputImage = _createInputImage(_latestImage!);
      if (inputImage != null) {
        final faces = await _faceDetector!.processImage(inputImage);
        
        if (mounted) {
          setState(() {
            if (faces.isNotEmpty) {
              final face = faces.first;
              final smileProb = face.smilingProbability;
              final smileText = smileProb != null 
                  ? '😄 Smile: ${(smileProb * 100).toStringAsFixed(1)}%'
                  : '😐 Smile: Unknown';
              
              _faceInfo = '✅ Found ${faces.length} face(s)\n$smileText';
            } else {
              _faceInfo = '👤 No faces detected';
            }
          });
        }
      }
    } catch (e) {
      print('❌ Face detection error: $e');
      if (mounted) {
        setState(() => _faceInfo = '❌ Detection error: $e');
      }
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _createInputImage(CameraImage image) {
    try {
      final camera = _controller!.description;
      
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
      print('❌ Error creating InputImage: $e');
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

  Future<void> _switchCamera() async {
    if (_controller == null) return;

    await _controller!.stopImageStream();
    _processingTimer?.cancel();
    
    setState(() {
      _cameraIndex = _cameraIndex == 0 ? 1 : 0;
      _status = '🔄 Switching camera...';
    });
    
    await _controller!.dispose();
    await _initializeCamera();
    _startPeriodicProcessing();
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Optimized Face Detection'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  _faceInfo,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Processing: Every ${PROCESSING_INTERVAL.inMilliseconds}ms (Optimized for older devices)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Camera preview
          Expanded(
            child: _controller != null && _controller!.value.isInitialized
                ? ClipRect(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading camera...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
