import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui';

class CameraModesApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraModesApp({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraModesApp> createState() => _CameraModesAppState();
}

class _CameraModesAppState extends State<CameraModesApp> {
  CameraController? _cameraController;
  bool _isPortraitMode = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isNotEmpty) {
      _cameraController = CameraController(
        widget.cameras.first,
        ResolutionPreset.high,
      );

      try {
        await _cameraController!.initialize();
        setState(() {});
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    }
  }

  @override
  void dispose() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController?.dispose();
    }
    super.dispose();
  }

  void _togglePortraitMode() {
    setState(() {
      _isPortraitMode = !_isPortraitMode;
      print('Portrait mode toggled: $_isPortraitMode');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Modes'),
        actions: [
          IconButton(
            icon: Icon(_isPortraitMode ? Icons.blur_on : Icons.blur_off),
            onPressed: () {
              print('Button pressed');
              _togglePortraitMode();
            },
          ),
        ],
      ),
      body: _cameraController != null && _cameraController!.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController!),
                if (_isPortraitMode)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                if (_isPortraitMode)
                  Center(
                    child: Container(
                      width: 200,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(home: CameraModesApp(cameras: cameras)));
}