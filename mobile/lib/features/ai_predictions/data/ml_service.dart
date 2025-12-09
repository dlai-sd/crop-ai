import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// ML Service for TensorFlow Lite model inference
abstract class MLService {
  /// Initialize and load models
  Future<void> initialize();

  /// Release resources
  Future<void> dispose();

  /// Predict disease from image
  Future<Map<String, dynamic>> predictDisease(Uint8List imageBytes);

  /// Predict yield from features
  Future<Map<String, dynamic>> predictYield(List<double> features);

  /// Predict growth stage from image
  Future<Map<String, dynamic>> predictGrowthStage(Uint8List imageBytes);
}

/// Mock implementation for testing and development
class MockMLService extends MLService {
  @override
  Future<void> initialize() async {
    // Simulate model loading
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> dispose() async {
    // Cleanup
  }

  @override
  Future<Map<String, dynamic>> predictDisease(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock disease prediction
    return {
      'disease': 'Early Blight',
      'confidence': 0.87,
      'class_id': 2,
      'treatments': [
        'Apply fungicide spray',
        'Prune affected leaves',
        'Improve air circulation',
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> predictYield(List<double> features) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Mock yield prediction (simple linear regression)
    final baseYield = 3000.0; // kg/hectare baseline
    final prediction = baseYield + (features[0] * 10); // Temperature influence
    final stdDev = 200.0;

    return {
      'yield': prediction,
      'std_dev': stdDev,
      'risk_factors': ['Low rainfall', 'High pest pressure'],
      'opportunities': ['Improved irrigation', 'Better fertilizer timing'],
    };
  }

  @override
  Future<Map<String, dynamic>> predictGrowthStage(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    // Mock growth stage prediction
    return {
      'stage_id': 2, // Vegetative
      'stage_name': 'vegetative',
      'confidence': 0.92,
      'days_since_planting': 35.0,
    };
  }
}

/// Image preprocessing utilities
class ImagePreprocessor {
  static const int MODEL_INPUT_SIZE = 224;
  static const double NORMALIZE_MIN = -1.0;
  static const double NORMALIZE_MAX = 1.0;

  /// Preprocess image for model input
  /// - Resize to 224x224
  /// - Normalize to [-1, 1]
  static Uint8List preprocessImage(Uint8List imageBytes) {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to model input size
    final resized = img.copyResize(
      image,
      width: MODEL_INPUT_SIZE,
      height: MODEL_INPUT_SIZE,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized bytes
    final List<int> output = [];
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixelSafe(x, y);
        // Get RGB values and normalize to [-1, 1]
        output.add(((pixel.r as int) / 127.5 - 1.0).toInt());
        output.add(((pixel.g as int) / 127.5 - 1.0).toInt());
        output.add(((pixel.b as int) / 127.5 - 1.0).toInt());
      }
    }

    return Uint8List.fromList(output);
  }

  /// Get image dimensions
  static Future<({int width, int height})> getImageDimensions(
    Uint8List imageBytes,
  ) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    return (width: image.width, height: image.height);
  }

  /// Resize image to target size
  static Uint8List resizeImage(
    Uint8List imageBytes,
    int width,
    int height,
  ) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(
      image,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodePng(resized));
  }
}

/// Feature engineering for yield prediction
class FeatureEngineer {
  /// Normalize features to [0, 1] range
  static List<double> normalizeFeatures(List<double> features) {
    if (features.isEmpty) return [];

    final max = features.reduce((a, b) => a > b ? a : b);
    final min = features.reduce((a, b) => a < b ? a : b);
    final range = max - min;

    if (range == 0) return List.filled(features.length, 0.5);

    return features.map((f) => (f - min) / range).toList();
  }

  /// Calculate statistics for features
  static Map<String, double> calculateStats(List<double> features) {
    if (features.isEmpty) {
      return {'mean': 0, 'std_dev': 0, 'min': 0, 'max': 0};
    }

    final mean = features.reduce((a, b) => a + b) / features.length;
    final variance = features
        .map((f) => (f - mean) * (f - mean))
        .reduce((a, b) => a + b) /
        features.length;
    final stdDev = variance.isFinite ? variance.sqrt() : 0;
    final min = features.reduce((a, b) => a < b ? a : b);
    final max = features.reduce((a, b) => a > b ? a : b);

    return {
      'mean': mean,
      'std_dev': stdDev,
      'min': min,
      'max': max,
    };
  }
}
