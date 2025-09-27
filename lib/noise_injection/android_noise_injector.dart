import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../ml/tflite_ensemble.dart';
import 'native_idct_safe.dart';

/// Enhanced noise injector optimized for Android with ensemble prediction
/// Stores images in app-specific directories and manages memory efficiently
class AndroidOptimizedNoiseInjector {
  static final TFLiteEnsemblePredictor _ensemble = TFLiteEnsemblePredictor();
  static bool _initialized = false;
  static Directory? _outputDir;

  /// Initialize the noise injector
  static Future<bool> init() async {
    if (_initialized) return true;

    try {
      print('🚀 Initializing Android Optimized Noise Injector...');

      // Initialize ensemble predictor
      final ensembleInit = await _ensemble.init();
      if (!ensembleInit) {
        print('⚠️  Ensemble predictor failed to initialize, using fallback');
      }

      // Initialize native IDCT (optional)
      NativeFastIdct.init();

      // Setup output directory
      await _setupOutputDirectory();

      _initialized = true;
      print('✅ Android Optimized Noise Injector initialized');
      return true;
    } catch (e) {
      print('❌ Failed to initialize noise injector: $e');
      return false;
    }
  }

  /// Setup output directory in app documents
  static Future<void> _setupOutputDirectory() async {
    try {
      // Use temporary directory for broader compatibility
      _outputDir = await getTemporaryDirectory();

      print('📁 Output directory set to temporary: ${_outputDir!.path}');
    } catch (e) {
      print('⚠️  Failed to setup output directory: $e');
      // Fallback to a directory within the app's documents directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _outputDir = Directory('${appDir.path}/noised_images');
        if (!await _outputDir!.exists()) {
          await _outputDir!.create(recursive: true);
        }
        print('📁 Fallback output directory: ${_outputDir!.path}');
      } catch (e2) {
        print('❌ Critical failure: Could not create any output directory: $e2');
      }
    }
  }

  /// Inject noise into image with ensemble prediction
  static Future<Map<String, dynamic>?> injectNoise({
    required Uint8List imageBytes,
    String? filename,
    double amplitudeFactor = 0.5,
    double frequencyFactor = 0.3,
    double phaseFactor = 0.4,
    double spatialFactor = 0.6,
    double temporalFactor = 0.2,
    int? noiseSeed,
    double blendFactor = 0.8,
    bool useEnsemble = true,
  }) async {
    if (!_initialized) {
      final initSuccess = await init();
      if (!initSuccess) {
        print('❌ Failed to initialize noise injector');
        return null;
      }
    }

    final stopwatch = Stopwatch()..start();

    try {
      print('🎯 Starting noise injection...');

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      // Validate image dimensions
      if (image.width <= 0 || image.height <= 0) {
        print('❌ Invalid image dimensions: ${image.width}x${image.height}');
        throw img.ImageException('Invalid image dimensions');
      }

      print('📸 Image loaded: ${image.width}x${image.height}');

      // Use ensemble prediction if enabled and available
      Map<String, double>? predictedParams;
      // if (useEnsemble) {
      //   predictedParams = await _predictParameters(image);
      //   if (predictedParams != null) {
      //     amplitudeFactor = predictedParams['amplitude_factor'] ?? amplitudeFactor;
      //     frequencyFactor = predictedParams['frequency_factor'] ?? frequencyFactor;
      //     phaseFactor = predictedParams['phase_factor'] ?? phaseFactor;
      //     spatialFactor = predictedParams['spatial_factor'] ?? spatialFactor;
      //     temporalFactor = predictedParams['temporal_factor'] ?? temporalFactor;
      //     noiseSeed = (predictedParams['noise_seed'] ?? noiseSeed ?? 42).round();
      //     blendFactor = predictedParams['blend_factor'] ?? blendFactor;
      //     print('🤖 Using ensemble-predicted parameters');
      //   }
      // }

      // Apply simple spatial noise injection (simplified for reliability)
      final noisedImage = _applySimpleNoise(
        image,
        amplitudeFactor,
        noiseSeed ?? 42,
        blendFactor,
      );

      // Save to output directory
      final outputPath = await _saveNoisedImage(noisedImage, filename);

      stopwatch.stop();

      final result = {
        'success': true,
        'output_path': outputPath,
        'processing_time_ms': stopwatch.elapsedMilliseconds,
        'image_size': '${image.width}x${image.height}',
        'parameters': {
          'amplitude_factor': amplitudeFactor,
          'frequency_factor': frequencyFactor,
          'phase_factor': phaseFactor,
          'spatial_factor': spatialFactor,
          'temporal_factor': temporalFactor,
          'noise_seed': noiseSeed,
          'blend_factor': blendFactor,
        },
        'ensemble_used': predictedParams != null,
      };

      print(
        '✅ Noise injection completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      print('📁 Output saved to: $outputPath');

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      print('❌ Noise injection failed: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'processing_time_ms': stopwatch.elapsedMilliseconds,
      };
    }
  }

  /// Predict noise parameters using ensemble
  static Future<Map<String, double>?> _predictParameters(
    img.Image image,
  ) async {
    try {
      // Extract features from image (simplified)
      final features = _extractImageFeatures(image);

      // Use ensemble to predict parameters
      final prediction = await _ensemble.predictParameters(features);

      return prediction;
    } catch (e) {
      print('⚠️  Parameter prediction failed: $e');
      return null;
    }
  }

  /// Extract basic image features for ML prediction
  static List<double> _extractImageFeatures(img.Image image) {
    // Simplified feature extraction to match scaler (3 features)
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final aspectRatio = width > 0 && height > 0 ? width / height : 1.0;

    // Normalize features to match training data range
    return [
      width / 1000.0, // Normalized width
      height / 1000.0, // Normalized height
      aspectRatio, // Aspect ratio
    ];
  }

  /// Apply simple spatial noise to image
  static img.Image _applySimpleNoise(
    img.Image image,
    double amplitudeFactor,
    int noiseSeed,
    double blendFactor,
  ) {
    final random = math.Random(noiseSeed);
    final result = img.Image.from(image);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        // Add random noise to each color channel
        final rNoise = ((random.nextDouble() - 0.5) * amplitudeFactor * 50)
            .round();
        final gNoise = ((random.nextDouble() - 0.5) * amplitudeFactor * 50)
            .round();
        final bNoise = ((random.nextDouble() - 0.5) * amplitudeFactor * 50)
            .round();

        final newR = (pixel.r + rNoise).clamp(0, 255).toInt();
        final newG = (pixel.g + gNoise).clamp(0, 255).toInt();
        final newB = (pixel.b + bNoise).clamp(0, 255).toInt();

        result.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }

    return result;
  }

  /// Save noised image to output directory
  static Future<String> _saveNoisedImage(
    img.Image image,
    String? filename,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = filename ?? 'noised_$timestamp.jpg';
    final outputFile = File('${tempDir.path}/$name');

    final jpegBytes = img.encodeJpg(image, quality: 95);
    await outputFile.writeAsBytes(jpegBytes);

    // Save to gallery
    try {
      await Gal.putImage(outputFile.path);
      print('✅ Image saved to gallery: ${outputFile.path}');
    } catch (e) {
      print('⚠️  Failed to save image to gallery: $e');
    }

    return outputFile.path;
  }

  /// Get output directory path
  static String? getOutputDirectory() {
    return _outputDir?.path;
  }

  /// Clear output directory
  static Future<void> clearOutputDirectory() async {
    try {
      if (_outputDir != null && await _outputDir!.exists()) {
        await for (final file in _outputDir!.list()) {
          if (file is File) {
            await file.delete();
          }
        }
        print('🧹 Output directory cleared');
      }
    } catch (e) {
      print('⚠️  Failed to clear output directory: $e');
    }
  }

  /// Dispose and clear memory
  static void dispose() {
    try {
      _ensemble.dispose();
      _initialized = false;
      print('🧹 Android Optimized Noise Injector disposed');
    } catch (e) {
      print('⚠️  Error disposing noise injector: $e');
    }
  }

  /// Get status information
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'output_directory': _outputDir?.path,
      'ensemble_status': _ensemble.getStatus(),
      'native_idct_available': false, // Always false in safe mode
    };
  }
}
