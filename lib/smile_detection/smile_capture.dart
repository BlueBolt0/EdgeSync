// Smile detection camera widget that captures a photo when majority of faces are smiling.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class SmileCapture extends StatefulWidget {
  final CameraController cameraController;
  final bool? isOldDevice;

  const SmileCapture({
    super.key, 
    required this.cameraController,
    this.isOldDevice,
  });

  @override
  State<SmileCapture> createState() => _SmileCaptureState();
}

class _SmileCaptureState extends State<SmileCapture> {
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
    
    if (widget.isOldDevice != null) {
      _isOldDevice = widget.isOldDevice!;
    } else {
      _detectDevicePerformance();
    }
    _processInterval = _isOldDevice ? kOldDeviceInterval : kNewDeviceInterval;
    
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
    _startImageStream();
  }

  void _detectDevicePerformance() {
    if (Platform.isAndroid) {
      try {
        _isOldDevice = _isLikelyOldDevice();
        print('SmileCapture - Device performance detected: ${_isOldDevice ? "Old" : "New"} device');
      } catch (e) {
        _isOldDevice = true;
        print('SmileCapture - Device detection failed, using conservative settings: $e');
      }
    } else {
      _isOldDevice = false;
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

  void _startImageStream() {
    widget.cameraController.startImageStream((cameraImage) async {
      _latestImage = cameraImage;
    });

    _processingTimer = Timer.periodic(_processInterval, (timer) {
      if (_latestImage != null && !_isDetecting && _countdown == 0) {
        _processLatestImage();
      }
    });
  }

  Future<void> _processLatestImage() async {
  if (_latestImage == null || _isDetecting || !_smileCaptureEnabled) return;

    _isDetecting = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertCameraImage(_latestImage!);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        // Limit faces processed for performance
        final limitedFaces = faces.take(MAX_FACES_TO_PROCESS).toList();
        int smilingCount = limitedFaces
            .where((face) => (face.smilingProbability ?? 0) >= 0.6)
            .length;

        if (smilingCount / limitedFaces.length >= 0.5) {
          _startCountdown();
        }
      }
    } catch (_) {
      // Silently ignore errors
    }

    _isDetecting = false;
  }

  // Converts camera image to ML Kit InputImage with improved format handling
  InputImage _convertCameraImage(CameraImage cameraImage) {
    try {
      final plane = cameraImage.planes[0];
      
      // Determine the input image format based on camera image format
      InputImageFormat format;
      switch (cameraImage.format.group) {
        case ImageFormatGroup.nv21:
          format = InputImageFormat.nv21;
          break;
        case ImageFormatGroup.yuv420:
          format = InputImageFormat.yuv420;
          break;
        default:
          format = InputImageFormat.nv21; // Default fallback
      }
      
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      // Fallback to original method if format detection fails
      final plane = cameraImage.planes[0];
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }
  }

  void _startCountdown() {
    if (_timer != null && _timer!.isActive) return;

    setState(() {
      _countdown = 3; // 3-second timer
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        await _takePicture();
        
        // Optional: Add a brief pause before allowing next detection
        await Future.delayed(const Duration(seconds: 2));
      }
    });
  }

  Future<void> _takePicture() async {
    try {
      if (!widget.cameraController.value.isInitialized ||
          widget.cameraController.value.isTakingPicture) {
        return;
      }

      final XFile file = await widget.cameraController.takePicture();
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path =
          '${directory.path}/smile_capture_$_photoIndex.jpg';
      _photoIndex++;

      await File(file.path).copy(path);
      // Photo saved locally with custom filename
    } catch (_) {
      // Silently ignore errors
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    _timer?.cancel();
    _processingTimer?.cancel();
    super.dispose();
  }

  void togglePerformanceMode() {
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
    
    print('SmileCapture - Performance Mode: ${_isOldDevice ? "Old" : "New"} device (${_processInterval.inMilliseconds}ms)');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(widget.cameraController),
        Positioned(
          top: 20,
          right: 20,
          child: Row(
            children: [
              const Text('Smile Capture'),
              Switch(
                value: _smileCaptureEnabled,
                onChanged: (val) {
                  setState(() {
                    _smileCaptureEnabled = val;
                  });
                },
              ),
            ],
          ),
        ),
        if (_countdown > 0)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
