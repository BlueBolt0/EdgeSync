import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:async';

void main() => runApp(WorkingFaceApp());

class WorkingFaceApp extends StatelessWidget {
  const WorkingFaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Working Face Detection',
      home: WorkingFaceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WorkingFaceScreen extends StatefulWidget {
  const WorkingFaceScreen({super.key});

  @override
  _WorkingFaceScreenState createState() => _WorkingFaceScreenState();
}

class _WorkingFaceScreenState extends State<WorkingFaceScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;
  bool _isDetecting = false;
  int _selectedCameraIdx = 1; // Front camera
  
  // Detection state
  String _status = 'Initializing...';
  double _smileProbability = 0.0;
  Color _statusColor = Colors.orange;
  int _frameCount = 0;
  int _detectionCount = 0;
  int _successCount = 0;
  String _debugInfo = '';
  
  late FaceDetector _faceDetector;
  
  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }
  
  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    print('📷 Face detector initialized');
  }
  
  Future<void> _initializeCamera() async {
    try {
      print('📷 Requesting camera permission...');
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _status = 'Camera permission denied';
          _statusColor = Colors.red;
        });
        return;
      }

      print('📷 Getting available cameras...');
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        setState(() {
          _status = 'No cameras found';
          _statusColor = Colors.red;
        });
        return;
      }

      print('📷 Found ${cameras!.length} cameras');
      await _initializeCameraController();

    } catch (e) {
      print('❌ Camera initialization error: $e');
      setState(() {
        _status = 'Camera error: $e';
        _statusColor = Colors.red;
      });
    }
  }
  
  Future<void> _initializeCameraController() async {
    try {
      // Try different image formats that are more compatible with MLKit
      final formats = [
        ImageFormatGroup.nv21,  // Most compatible with Android
        ImageFormatGroup.yuv420,
      ];
      
      bool initialized = false;
      
      for (final format in formats) {
        try {
          print('📷 Trying image format: $format');
          
          _controller = CameraController(
            cameras![_selectedCameraIdx],
            ResolutionPreset.medium,
            imageFormatGroup: format,
            enableAudio: false,
          );

          await _controller!.initialize();
          print('✅ Camera initialized with format $format');
          
          _controller!.startImageStream(_processImage);
          initialized = true;
          break;
          
        } catch (e) {
          print('❌ Format $format error: $e');
          await _controller?.dispose();
        }
      }
      
      if (initialized) {
        setState(() {
          _isInitialized = true;
          _status = 'Camera ready - Looking for faces...';
          _statusColor = Colors.blue;
        });
      } else {
        setState(() {
          _status = 'Camera format not supported';
          _statusColor = Colors.red;
        });
      }

    } catch (e) {
      print('❌ Camera controller initialization error: $e');
      setState(() {
        _status = 'Camera init failed: $e';
        _statusColor = Colors.red;
      });
    }
  }
  
  void _processImage(CameraImage image) {
    if (_isDetecting) return;
    _isDetecting = true;
    
    _frameCount++;
    
    // Update debug info every 30 frames
    if (_frameCount % 30 == 0) {
      setState(() {
        _debugInfo = 'Frames: $_frameCount, Attempts: $_detectionCount, Success: $_successCount';
      });
    }
    
    _detectFaces(image).then((_) {
      _isDetecting = false;
    }).catchError((error) {
      print('❌ Face detection error: $error');
      _isDetecting = false;
    });
  }
  
  Future<void> _detectFaces(CameraImage image) async {
    try {
      final inputImage = _createInputImage(image);
      if (inputImage == null) {
        return;
      }
      
      _detectionCount++;
      final faces = await _faceDetector.processImage(inputImage);
      _successCount++;
      
      if (!mounted) return;
      
      setState(() {
        if (faces.isEmpty) {
          _status = 'No face detected';
          _smileProbability = 0.0;
          _statusColor = Colors.red;
        } else {
          print('✅ Found ${faces.length} face(s)');
          final face = faces.first;
          _status = '😊 Face detected!';
          _statusColor = Colors.green;
          
          final smiling = face.smilingProbability;
          if (smiling != null) {
            _smileProbability = smiling;
            print('😄 Smile probability: ${(smiling * 100).toStringAsFixed(1)}%');
          } else {
            _smileProbability = 0.0;
          }
        }
      });
      
    } catch (e) {
      print('❌ Face detection processing error: $e');
      if (mounted) {
        setState(() {
          _status = 'Detection error';
          _statusColor = Colors.orange;
        });
      }
    }
  }
  
  InputImage? _createInputImage(CameraImage image) {
    try {
      // Handle different image formats
      final camera = cameras![_selectedCameraIdx];
      final isBackCamera = camera.lensDirection == CameraLensDirection.back;
      
      InputImageRotation rotation;
      if (isBackCamera) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }
      
      InputImageFormat? format;
      
      // Map camera image format to MLKit format
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          format = InputImageFormat.yuv420;
          break;
        case ImageFormatGroup.nv21:
          format = InputImageFormat.nv21;
          break;
        case ImageFormatGroup.jpeg:
          format = InputImageFormat.yuv420; // Fallback
          break;
        default:
          print('⚠️ Unsupported image format: ${image.format.group}');
          return null;
      }
      
      if (image.planes.isEmpty) {
        print('⚠️ No image planes available');
        return null;
      }
      
      final plane = image.planes.first;
      if (plane.bytes.isEmpty) {
        print('⚠️ Empty image data');
        return null;
      }
      
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
      
      return inputImage;
      
    } catch (e) {
      print('❌ Input image creation error: $e');
      return null;
    }
  }
  
  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    
    try {
      await _controller?.stopImageStream();
      await _controller?.dispose();
      
      _selectedCameraIdx = (_selectedCameraIdx + 1) % cameras!.length;
      print('📷 Switching to camera $_selectedCameraIdx');
      
      setState(() {
        _isInitialized = false;
        _status = 'Switching camera...';
        _statusColor = Colors.blue;
        _frameCount = 0;
        _detectionCount = 0;
        _successCount = 0;
      });
      
      await _initializeCameraController();
      
    } catch (e) {
      print('❌ Camera switch error: $e');
      setState(() {
        _status = 'Switch failed';
        _statusColor = Colors.red;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working Face Detection'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _isInitialized && _controller != null
                  ? CameraPreview(_controller!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            _isInitialized ? 'Camera ready' : 'Setting up camera...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Status and controls
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Main status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    border: Border.all(color: _statusColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _status.contains('detected') 
                            ? Icons.face 
                            : Icons.face_retouching_off,
                        color: _statusColor,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Smile display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_satisfied,
                            color: _smileProbability > 0.3 ? Colors.orange : Colors.grey,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Smile: ${(_smileProbability * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (_smileProbability > 0.7)
                            Text(
                              '😄',
                              style: TextStyle(fontSize: 20),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      LinearProgressIndicator(
                        value: _smileProbability,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _smileProbability > 0.5 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Debug info
                Text(
                  _debugInfo.isEmpty ? 'Getting ready...' : _debugInfo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Instructions
                Text(
                  'Point the camera at your face and smile! 😊',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    print('📷 Disposing camera and face detector...');
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
