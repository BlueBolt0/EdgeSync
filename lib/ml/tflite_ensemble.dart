import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Enhanced TFLite ensemble predictor optimized for Android
/// Uses models 1, 4, and 5 with proper memory management
class TFLiteEnsemblePredictor {
  static const List<int> _modelFolds = [1, 4, 5];
  final Map<int, Interpreter> _interpreters = {};
  final Map<int, Map<String, dynamic>> _scalers = {};
  bool _initialized = false;

  /// Initialize all models and scalers
  Future<bool> init() async {
    if (_initialized) return true;
    
    try {
      print('🚀 Initializing TFLite ensemble predictor...');
      
      for (int fold in _modelFolds) {
        // Load model
        final modelPath = 'assets/models/fold_${fold}_dynamic.tflite';
        final scalerPath = 'assets/models/fold_${fold}_dynamic_scaler.json';
        
        // Load TFLite model
        try {
          final interpreter = await Interpreter.fromAsset(modelPath);
          _interpreters[fold] = interpreter;
          print('✅ Loaded model fold $fold');
        } catch (e) {
          print('❌ Failed to load model fold $fold: $e');
          continue;
        }
        
        // Load scaler
        try {
          final scalerData = await rootBundle.loadString(scalerPath);
          _scalers[fold] = json.decode(scalerData);
          print('✅ Loaded scaler fold $fold');
        } catch (e) {
          print('❌ Failed to load scaler fold $fold: $e');
          continue;
        }
      }
      
      if (_interpreters.isEmpty) {
        print('❌ No models loaded successfully');
        return false;
      }
      
      _initialized = true;
      print('✅ TFLite ensemble initialized with ${_interpreters.length} models');
      return true;
      
    } catch (e) {
      print('❌ Failed to initialize TFLite ensemble: $e');
      return false;
    }
  }
  
  /// Predict noise parameters using ensemble of models
  Future<Map<String, double>?> predictParameters(List<double> features) async {
    if (!_initialized || _interpreters.isEmpty) {
      print('⚠️  TFLite ensemble not initialized');
      return null;
    }
    
    try {
      final predictions = <Map<String, double>>[];
      
      // Run prediction on each model
      for (int fold in _interpreters.keys) {
        final interpreter = _interpreters[fold];
        final scaler = _scalers[fold];
        
        if (interpreter == null || scaler == null) continue;
        
        try {
          // Scale features
          final scaledFeatures = _scaleFeatures(features, scaler);
          
          // Prepare input
          final input = [scaledFeatures];
          
          // Prepare output
          final output = [List.filled(3, 0.0)]; // 3 parameters: amplitude, frequency, blend
          
          // Run inference
          interpreter.run(input, output);
          
          // Inverse scale output
          final prediction = _inverseScaleOutput(output[0], scaler);
          predictions.add(prediction);
          
        } catch (e) {
          print('⚠️  Model fold $fold prediction failed: $e');
          continue;
        }
      }
      
      if (predictions.isEmpty) {
        print('❌ All model predictions failed');
        return null;
      }
      
      // Ensemble averaging
      final ensemble = _ensembleAverage(predictions);
      
      print('✅ Ensemble prediction completed with ${predictions.length} models');
      return ensemble;
      
    } catch (e) {
      print('❌ Ensemble prediction failed: $e');
      return null;
    }
  }
  
  /// Scale input features using loaded scaler
  List<double> _scaleFeatures(List<double> features, Map<String, dynamic> scaler) {
    final mean = List<double>.from(scaler['mean']);
    final scale = List<double>.from(scaler['scale']);
    
    final scaled = <double>[];
    for (int i = 0; i < features.length; i++) {
      scaled.add((features[i] - mean[i]) / scale[i]);
    }
    return scaled;
  }
  
  /// Inverse scale output using loaded scaler
  Map<String, double> _inverseScaleOutput(List<double> output, Map<String, dynamic> scaler) {
    final outputMean = List<double>.from(scaler['output_mean'] ?? [0.5, 0.3, 0.8]); // Default values
    final outputScale = List<double>.from(scaler['output_scale'] ?? [0.2, 0.1, 0.1]); // Default values
    
    final unscaled = <double>[];
    for (int i = 0; i < output.length; i++) {
      unscaled.add((output[i] * outputScale[i]) + outputMean[i]);
    }
    
    return {
      'amplitude_factor': unscaled[0].clamp(0.1, 1.0),
      'frequency_factor': unscaled[1].clamp(0.1, 1.0), 
      'blend_factor': unscaled[2].clamp(0.3, 1.0),
      'phase_factor': 0.4, // Default values for unused parameters
      'spatial_factor': 0.6,
      'temporal_factor': 0.2,
      'noise_seed': 42.0,
    };
  }
  
  /// Ensemble averaging of predictions
  Map<String, double> _ensembleAverage(List<Map<String, double>> predictions) {
    final keys = predictions.first.keys.toList();
    final averaged = <String, double>{};
    
    for (String key in keys) {
      double sum = 0.0;
      for (var prediction in predictions) {
        sum += prediction[key] ?? 0.0;
      }
      averaged[key] = sum / predictions.length;
    }
    
    return averaged;
  }
  
  /// Clear models from memory (important for Android)
  void dispose() {
    try {
      for (var interpreter in _interpreters.values) {
        interpreter.close();
      }
      _interpreters.clear();
      _scalers.clear();
      _initialized = false;
      print('🧹 TFLite ensemble disposed and memory cleared');
    } catch (e) {
      print('⚠️  Error disposing TFLite ensemble: $e');
    }
  }
  
  /// Get model status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'models_loaded': _interpreters.length,
      'expected_models': _modelFolds.length,
      'available_folds': _interpreters.keys.toList(),
    };
  }
}
