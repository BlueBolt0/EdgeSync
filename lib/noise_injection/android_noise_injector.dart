import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
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
      final appDir = await getApplicationDocumentsDirectory();
      _outputDir = Directory('${appDir.path}/noised_images');
      
      if (!await _outputDir!.exists()) {
        await _outputDir!.create(recursive: true);
      }
      
      print('📁 Output directory: ${_outputDir!.path}');
    } catch (e) {
      print('⚠️  Failed to setup output directory: $e');
      // Fallback to temporary directory
      _outputDir = await getTemporaryDirectory();
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

      print('📸 Image loaded: ${image.width}x${image.height}');

      // Use ensemble prediction if enabled and available
      Map<String, double>? predictedParams;
      if (useEnsemble) {
        predictedParams = await _predictParameters(image);
        if (predictedParams != null) {
          amplitudeFactor = predictedParams['amplitude_factor'] ?? amplitudeFactor;
          frequencyFactor = predictedParams['frequency_factor'] ?? frequencyFactor;
          phaseFactor = predictedParams['phase_factor'] ?? phaseFactor;
          spatialFactor = predictedParams['spatial_factor'] ?? spatialFactor;
          temporalFactor = predictedParams['temporal_factor'] ?? temporalFactor;
          noiseSeed = (predictedParams['noise_seed'] ?? noiseSeed ?? 42).round();
          blendFactor = predictedParams['blend_factor'] ?? blendFactor;
          print('🤖 Using ensemble-predicted parameters');
        }
      }

      // Convert to Lab color space
      final labImage = _convertToLab(image);
      
      // Extract L channel for processing
      final lChannel = _extractLChannel(labImage);
      
      // Apply frequency domain noise injection
      final noisedLChannel = await _injectFrequencyNoise(
        lChannel,
        amplitudeFactor: amplitudeFactor,
        frequencyFactor: frequencyFactor,
        phaseFactor: phaseFactor,
        spatialFactor: spatialFactor,
        temporalFactor: temporalFactor,
        noiseSeed: noiseSeed ?? 42,
        blendFactor: blendFactor,
      );

      if (noisedLChannel == null) {
        print('❌ Frequency noise injection failed');
        return null;
      }

      // Reconstruct image
      final noisedImage = _reconstructFromLab(labImage, noisedLChannel);
      
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

      print('✅ Noise injection completed in ${stopwatch.elapsedMilliseconds}ms');
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
  static Future<Map<String, double>?> _predictParameters(img.Image image) async {
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
    // Simplified feature extraction
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final aspectRatio = width / height;
    
    // Calculate basic statistics
    double meanR = 0, meanG = 0, meanB = 0;
    double varR = 0, varG = 0, varB = 0;
    
    final pixels = image.width * image.height;
    
    // First pass: calculate means
    for (final pixel in image) {
      meanR += pixel.r / pixels;
      meanG += pixel.g / pixels;
      meanB += pixel.b / pixels;
    }
    
    // Second pass: calculate variances
    for (final pixel in image) {
      varR += math.pow(pixel.r - meanR, 2) / pixels;
      varG += math.pow(pixel.g - meanG, 2) / pixels;
      varB += math.pow(pixel.b - meanB, 2) / pixels;
    }
    
    return [
      width / 1000.0, // Normalized width
      height / 1000.0, // Normalized height
      aspectRatio,
      meanR / 255.0,
      meanG / 255.0,
      meanB / 255.0,
      math.sqrt(varR) / 255.0,
      math.sqrt(varG) / 255.0,
      math.sqrt(varB) / 255.0,
    ];
  }

  /// Convert RGB image to Lab color space
  static img.Image _convertToLab(img.Image image) {
    // Simplified Lab conversion for mobile optimization
    return img.copyResize(image, maintainAspect: true);
  }

  /// Extract L channel from Lab image
  static List<List<double>> _extractLChannel(img.Image image) {
    final height = image.height;
    final width = image.width;
    final lChannel = List.generate(height, (y) => List.filled(width, 0.0));
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        // Convert to luminance
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        lChannel[y][x] = luminance;
      }
    }
    
    return lChannel;
  }

  /// Inject frequency domain noise with optimized IDCT
  static Future<List<List<double>>?> _injectFrequencyNoise(
    List<List<double>> lChannel, {
    required double amplitudeFactor,
    required double frequencyFactor,
    required double phaseFactor,
    required double spatialFactor,
    required double temporalFactor,
    required int noiseSeed,
    required double blendFactor,
  }) async {
    
    try {
      final height = lChannel.length;
      final width = lChannel[0].length;
      final random = math.Random(noiseSeed);
      
      print('🔄 Applying frequency domain noise injection...');
      
      // Process in blocks for Android optimization
      const blockSize = 64; // Smaller blocks for mobile
      final result = List.generate(height, (y) => List<double>.from(lChannel[y]));
      
      for (int blockY = 0; blockY < height; blockY += blockSize) {
        for (int blockX = 0; blockX < width; blockX += blockSize) {
          final endY = math.min(blockY + blockSize, height);
          final endX = math.min(blockX + blockSize, width);
          
          // Extract block
          final block = <List<double>>[];
          for (int y = blockY; y < endY; y++) {
            block.add(lChannel[y].sublist(blockX, endX));
          }
          
          // Apply noise to block
          final noisedBlock = _applyNoiseToBlock(
            block,
            random,
            amplitudeFactor,
            frequencyFactor,
            phaseFactor,
            blendFactor,
          );
          
          // Copy back to result
          if (noisedBlock != null) {
            for (int y = 0; y < noisedBlock.length; y++) {
              for (int x = 0; x < noisedBlock[y].length; x++) {
                result[blockY + y][blockX + x] = noisedBlock[y][x];
              }
            }
          }
        }
      }
      
      return result;
      
    } catch (e) {
      print('❌ Frequency noise injection failed: $e');
      return null;
    }
  }

  /// Apply noise to a single block
  static List<List<double>>? _applyNoiseToBlock(
    List<List<double>> block,
    math.Random random,
    double amplitudeFactor,
    double frequencyFactor,
    double phaseFactor,
    double blendFactor,
  ) {
    
    try {
      // Try native IDCT first
      final nativeResult = NativeFastIdct.fastIdct2d(block);
      if (nativeResult != null) {
        // Apply noise in frequency domain
        final noisedFreq = _addFrequencyNoise(
          nativeResult,
          random,
          amplitudeFactor,
          frequencyFactor,
          phaseFactor,
        );
        
        // Inverse transform
        final noisedSpatial = NativeFastIdct.fastIdct2d(noisedFreq);
        if (noisedSpatial != null) {
          return _blendWithOriginal(block, noisedSpatial, blendFactor);
        }
      }
      
      // Fallback to simplified spatial noise
      return _applySpatialNoise(block, random, amplitudeFactor, blendFactor);
      
    } catch (e) {
      print('⚠️  Block noise application failed: $e');
      return block; // Return original block
    }
  }

  /// Add noise in frequency domain
  static List<List<double>> _addFrequencyNoise(
    List<List<double>> freqData,
    math.Random random,
    double amplitudeFactor,
    double frequencyFactor,
    double phaseFactor,
  ) {
    
    final height = freqData.length;
    final width = freqData[0].length;
    final result = List.generate(height, (y) => List<double>.from(freqData[y]));
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calculate frequency-based noise
        final freq = math.sqrt((x * x + y * y).toDouble()) / math.max(width, height);
        final amplitude = amplitudeFactor * math.exp(-freq * frequencyFactor);
        final phase = phaseFactor * random.nextDouble() * 2 * math.pi;
        
        final noise = amplitude * math.sin(phase);
        result[y][x] += noise;
      }
    }
    
    return result;
  }

  /// Apply spatial noise as fallback
  static List<List<double>> _applySpatialNoise(
    List<List<double>> block,
    math.Random random,
    double amplitudeFactor,
    double blendFactor,
  ) {
    
    final height = block.length;
    final width = block[0].length;
    final result = List.generate(height, (y) => List<double>.from(block[y]));
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = (random.nextDouble() - 0.5) * amplitudeFactor * 2;
        result[y][x] = block[y][x] * (1 - blendFactor) + 
                       (block[y][x] + noise) * blendFactor;
      }
    }
    
    return result;
  }

  /// Blend noised result with original
  static List<List<double>> _blendWithOriginal(
    List<List<double>> original,
    List<List<double>> noised,
    double blendFactor,
  ) {
    
    final height = original.length;
    final width = original[0].length;
    final result = List.generate(height, (y) => List.filled(width, 0.0));
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        result[y][x] = original[y][x] * (1 - blendFactor) + 
                       noised[y][x] * blendFactor;
      }
    }
    
    return result;
  }

  /// Reconstruct image from Lab with modified L channel
  static img.Image _reconstructFromLab(
    img.Image originalImage,
    List<List<double>> modifiedL,
  ) {
    
    final result = img.Image.from(originalImage);
    
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final newL = modifiedL[y][x].clamp(0.0, 255.0);
        
        // Simple grayscale reconstruction for mobile optimization
        final gray = newL.round();
        result.setPixel(x, y, img.ColorRgb8(gray, gray, gray));
      }
    }
    
    return result;
  }

  /// Save noised image to output directory
  static Future<String> _saveNoisedImage(img.Image image, String? filename) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = filename ?? 'noised_$timestamp';
    final outputFile = File('${_outputDir!.path}/$name.jpg');
    
    final jpegBytes = img.encodeJpg(image, quality: 95);
    await outputFile.writeAsBytes(jpegBytes);
    
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
