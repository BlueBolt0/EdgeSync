import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_app.dart'; // Your original camera app
import 'mode.dart'; // Enhanced camera with your features preserved
import 'enhanced_camera_with_original.dart'; // Complete enhanced version

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  final cameras = await availableCameras();
  
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeSync Camera',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: CameraSelection(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraSelection extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const CameraSelection({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EdgeSync Camera'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Camera Version',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select which camera experience you prefer',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Original Camera App Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraApp(),
                    ),
                  );
                },
                icon: const Icon(Icons.photo_camera),
                label: const Text(
                  'Original Camera',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Features list for original
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Features:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Smile detection & auto capture'),
                  Text('• Privacy & Harmoniser modes'),
                  Text('• Performance optimization'),
                  Text('• Video recording'),
                  Text('• Face detection with ML Kit'),
                  Text('• Photo/Portrait/Video modes'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Complete Enhanced Camera App Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnhancedCameraWithOriginalFeatures(),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Complete Enhanced Camera',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Features list for complete enhanced
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Enhanced Features:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• ALL original features preserved'),
                  Text('• Smile detection & auto capture'),
                  Text('• Privacy & Harmoniser modes'),
                  Text('• Performance optimization'),
                  Text('• Portrait mode with real effects'),
                  Text('• HDR, Night mode & Filters'),
                  Text('• Zoom, exposure, tap-to-focus'),
                  Text('• Grid overlay & enhanced UI'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Enhanced Camera App Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraModesApp(cameras: cameras),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_enhance),
                label: const Text(
                  'Demo Enhanced Camera',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Features list for enhanced
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enhanced Features:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• All original features PLUS:'),
                  Text('• Portrait mode with blur effects'),
                  Text('• HDR & Night mode'),
                  Text('• Color filters (B&W, Sepia, etc.)'),
                  Text('• Zoom & exposure controls'),
                  Text('• Tap-to-focus'),
                  Text('• Grid overlay'),
                  Text('• Enhanced UI'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
