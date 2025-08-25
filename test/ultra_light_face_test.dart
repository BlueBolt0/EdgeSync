import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() => runApp(UltraLightFaceApp());

class UltraLightFaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultra Light Face Detection',
      home: UltraLightFaceScreen(),
    );
  }
}

class UltraLightFaceScreen extends StatefulWidget {
  @override
  _UltraLightFaceScreenState createState() => _UltraLightFaceScreenState();
}

class _UltraLightFaceScreenState extends State<UltraLightFaceScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  String _status = 'Initializing...';
  String _faceInfo = 'No faces detected';
  int _cameraIndex = 0;
  Timer? _processingTimer;
  CameraImage? _latestImage;
  
  // Ultra-conservative settings for older phones
  static const Duration PROCESSING_INTERVAL = Duration(seconds: 2); // Only every 2 seconds!
  static const int MAX_DETECTIONS_PER_SESSION = 10; // Limit total detections
  int _detectionCount = 0;
  
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
          enableClassification: true,  // Keep smile detection
          enableLandmarks: false,      // Disable everything else
          enableContours: false,       
          enableTracking: false,       
          minFaceSize: 0.3,           // Only detect larger faces (less processing)
          performanceMode: FaceDetectorMode.fast, // Use fast mode
        ),
      );
      setState(() => _status = '✅ Ultra-light face detector initialized');
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

      _controller = CameraController(
        cameras[_cameraIndex],
        ResolutionPreset.low, // Use lowest resolution for better performance
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _status = '✅ Ultra-light camera initialized (low resolution)';
        });
      }
      
    } catch (e) {
      setState(() => _status = '❌ Camera initialization failed: $e');
    }
  }

  void _startPeriodicProcessing() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.startImageStream((CameraImage image) {
        // Only store latest image, don't process immediately
        _latestImage = image;
      });

      // Process images very infrequently
      _processingTimer = Timer.periodic(PROCESSING_INTERVAL, (timer) {
        if (_latestImage != null && !_isDetecting && _detectionCount < MAX_DETECTIONS_PER_SESSION) {
          _processLatestImage();
        }
      });
    }
  }

  Future<void> _processLatestImage() async {
    if (_latestImage == null || _isDetecting || _faceDetector == null) return;

    _isDetecting = true;
    _detectionCount++;
    
    setState(() {
      _faceInfo = '🔄 Processing... (${_detectionCount}/$MAX_DETECTIONS_PER_SESSION)';
    });
    
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
              
              _faceInfo = '✅ Found ${faces.length} face(s)\n$smileText\n(Detection ${_detectionCount}/$MAX_DETECTIONS_PER_SESSION)';
            } else {
              _faceInfo = '👤 No faces detected\n(Detection ${_detectionCount}/$MAX_DETECTIONS_PER_SESSION)';
            }
          });
        }
      }
    } catch (e) {
      print('❌ Face detection error: $e');
      if (mounted) {
        setState(() => _faceInfo = '❌ Detection error: $e\n(Detection ${_detectionCount}/$MAX_DETECTIONS_PER_SESSION)');
      }
    } finally {
      _isDetecting = false;
      
      // Stop processing after max detections to prevent overload
      if (_detectionCount >= MAX_DETECTIONS_PER_SESSION) {
        _processingTimer?.cancel();
        setState(() {
          _faceInfo += '\n\n⚠️ Stopped to prevent overload.\nTap "Reset" to continue.';
        });
      }
    }
  }

  InputImage? _createInputImage(CameraImage image) {
    try {
      final camera = _controller!.description;
      
      InputImageRotation rotation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      print('❌ Error creating InputImage: $e');
      return null;
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

  void _resetDetection() {
    _processingTimer?.cancel();
    _detectionCount = 0;
    setState(() {
      _faceInfo = 'Detection reset - starting fresh...';
    });
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
        title: Text('Ultra Light Face Detection'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetDetection,
            tooltip: 'Reset Detection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.green.withOpacity(0.1),
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
                  'Ultra-Light Mode: Every ${PROCESSING_INTERVAL.inSeconds}s, Max ${MAX_DETECTIONS_PER_SESSION} detections',
                  style: TextStyle(color: Colors.yellow, fontSize: 12),
                ),
                Text(
                  'Optimized for older devices 📱',
                  style: TextStyle(color: Colors.yellow, fontSize: 12, fontStyle: FontStyle.italic),
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
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Loading ultra-light camera...',
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
