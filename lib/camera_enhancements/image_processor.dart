/// Image processing and filter effects for camera modes
/// Safe implementation using proven image package functions
library image_processor;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'camera_modes.dart';

/// Processing progress callback
typedef ProcessingProgressCallback = void Function(double progress);

/// Processing result
class ProcessingResult {
  final File? processedFile;
  final String? error;
  final Duration processingTime;

  const ProcessingResult({
    this.processedFile,
    this.error,
    required this.processingTime,
  });

  bool get isSuccess => processedFile != null && error == null;
}

/// Main image processor class for applying effects and filters
class ImageProcessor {
  /// Process image with safe, proven effects
  static Future<File?> processImage(
    File originalFile,
    CameraMode mode,
    FilterType filter, {
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      
      // Read the original image
      final Uint8List imageBytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        debugPrint('Error: Could not decode image');
        return null;
      }

      onProgress?.call(0.3);

      // Apply filter effects first (these are safe and proven)
      if (filter != FilterType.none) {
        image = _applySafeFilter(image, filter);
        onProgress?.call(0.6);
      }

      // Apply mode-specific effects (using only safe operations)
      if (mode != CameraMode.normal) {
        image = _applySafeModeEffect(image, mode);
        onProgress?.call(0.8);
      }

      // Save the processed image
      final String originalPath = originalFile.path;
      final String extension = originalPath.split('.').last.toLowerCase();
      final String processedPath = originalPath.replaceAll(
        '.$extension',
        '_processed_${mode.name}_${filter.name}.$extension',
      );

      Uint8List? encodedImage;
      if (extension == 'jpg' || extension == 'jpeg') {
        encodedImage = Uint8List.fromList(img.encodeJpg(image, quality: 95));
      } else {
        encodedImage = Uint8List.fromList(img.encodePng(image));
      }

      final File processedFile = File(processedPath);
      await processedFile.writeAsBytes(encodedImage);

      onProgress?.call(1.0);

      debugPrint('Image processing completed: $mode mode, $filter filter');
      
      return processedFile;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  /// Apply filters using only safe, built-in image package functions
  static img.Image _applySafeFilter(img.Image image, FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return image;
        
      case FilterType.grayscale:
        // Use built-in grayscale function - this is 100% safe
        return img.grayscale(image);
        
      case FilterType.sepia:
        // Use built-in sepia function - this is 100% safe
        return img.sepia(image);
        
      case FilterType.vintage:
        // Safe approach: use built-in adjustColor with conservative values
        var processed = img.adjustColor(image, 
          saturation: 0.8,  // Slightly reduced saturation
          contrast: 1.1,    // Slight contrast boost
          brightness: 1.05, // Slight brightness boost
        );
        // Add warm tint safely
        return img.adjustColor(processed,
          hue: 10,  // Use degrees instead of fractional values
        );
        
      case FilterType.vivid:
        // Safe vivid effect with conservative values
        return img.adjustColor(image,
          saturation: 1.3,  // Moderate saturation boost
          contrast: 1.2,    // Moderate contrast boost
          brightness: 1.02, // Very slight brightness boost
        );
        
      case FilterType.cold:
        // Safe cold tone effect
        return img.adjustColor(image,
          hue: -15,         // Cool blue shift in degrees
          saturation: 1.05, // Slight saturation boost
        );
        
      case FilterType.warm:
        // Safe warm tone effect
        return img.adjustColor(image,
          hue: 15,          // Warm orange shift in degrees
          saturation: 1.1,  // Slight saturation boost
          brightness: 1.02, // Very slight brightness boost
        );
    }
  }

  /// Apply mode effects using only safe operations
  static img.Image _applySafeModeEffect(img.Image image, CameraMode mode) {
    switch (mode) {
      case CameraMode.portrait:
        // Safe portrait effect: just enhance contrast and saturation slightly
        return img.adjustColor(image,
          contrast: 1.08,   // Very subtle contrast boost
          saturation: 1.05, // Very subtle saturation boost
        );
        
      case CameraMode.hdr:
        // Safe HDR simulation with conservative values
        return img.adjustColor(image,
          contrast: 1.15,   // Moderate contrast boost
          brightness: 1.05, // Slight brightness boost
          saturation: 1.1,  // Slight saturation boost
        );
        
      case CameraMode.night:
        // Safe night mode: just brighten the image
        return img.adjustColor(image,
          brightness: 1.2,  // Moderate brightness boost
          contrast: 1.05,   // Very slight contrast boost
        );
        
      case CameraMode.filters:
      case CameraMode.normal:
        return image;
    }
  }

  /// Create a simple color matrix effect for preview
  static ColorFilter? getPreviewColorFilter(FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return null;
        
      case FilterType.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        
      case FilterType.sepia:
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        
      case FilterType.vintage:
        return const ColorFilter.matrix(<double>[
          0.9, 0.5, 0.1, 0, 0,
          0.3, 0.8, 0.1, 0, 0,
          0.2, 0.3, 0.5, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        
      case FilterType.vivid:
        return const ColorFilter.matrix(<double>[
          1.3, 0, 0, 0, 0,
          0, 1.3, 0, 0, 0,
          0, 0, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        
      case FilterType.cold:
        return const ColorFilter.matrix(<double>[
          0.8, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        
      case FilterType.warm:
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 0,
          0, 1.1, 0, 0, 0,
          0, 0, 0.8, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  /// Get blur effect for portrait mode preview
  static double getPortraitBlurRadius(CameraMode mode) {
    return mode == CameraMode.portrait ? 2.0 : 0.0;
  }

  /// Get brightness adjustment for night mode preview
  static double getNightModeBrightness(CameraMode mode) {
    return mode == CameraMode.night ? 0.3 : 0.0;
  }

  /// Get saturation adjustment for HDR mode preview
  static double getHDRSaturation(CameraMode mode) {
    return mode == CameraMode.hdr ? 1.5 : 1.0;
  }
}

/// Preview effects manager for real-time camera preview
class PreviewEffectsManager {
  /// Get combined effects for camera preview
  static Widget buildPreviewWithEffects({
    required Widget cameraPreview,
    required CameraMode mode,
    required FilterType filter,
    double opacity = 1.0,
  }) {
    Widget preview = cameraPreview;

    // Apply color filter
    final ColorFilter? colorFilter = ImageProcessor.getPreviewColorFilter(filter);
    if (colorFilter != null) {
      preview = ColorFiltered(
        colorFilter: colorFilter,
        child: preview,
      );
    }

    // Apply mode-specific effects
    switch (mode) {
      case CameraMode.portrait:
        // Add a subtle overlay to simulate focus area
        preview = Stack(
          children: [
            preview,
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
        );
        break;
        
      case CameraMode.hdr:
        // Add brightness and contrast effect
        preview = ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1.15, 0, 0, 0, 10,
            0, 1.15, 0, 0, 10,
            0, 0, 1.15, 0, 10,
            0, 0, 0, 1, 0,
          ]),
          child: preview,
        );
        break;
        
      case CameraMode.night:
        // Add brightness boost
        preview = ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1, 0, 0, 0, 30,
            0, 1, 0, 0, 30,
            0, 0, 1, 0, 30,
            0, 0, 0, 1, 0,
          ]),
          child: preview,
        );
        break;
        
      case CameraMode.filters:
      case CameraMode.normal:
        // No additional mode effects
        break;
    }

    // Apply opacity if needed
    if (opacity < 1.0) {
      preview = Opacity(
        opacity: opacity,
        child: preview,
      );
    }

    return preview;
  }

  /// Create mode indicator overlay
  static Widget buildModeIndicator({
    required CameraMode mode,
    required FilterType filter,
  }) {
    if (mode == CameraMode.normal && filter == FilterType.none) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CameraModes.getIcon(mode),
                color: CameraModes.getColor(mode),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                CameraModes.getDisplayName(mode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (filter != FilterType.none) ...[
                const SizedBox(width: 8),
                Icon(
                  CameraFilters.getIcon(filter),
                  color: CameraFilters.getAccentColor(filter),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  CameraFilters.getDisplayName(filter),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
