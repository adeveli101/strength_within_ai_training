import 'dart:math' as math;
import '../core/logger.dart';



class FeatureNormalizer {
  final AILogger _logger = AILogger();

  // Normalization ranges
  static const double DEFAULT_MIN = 0.0;
  static const double DEFAULT_MAX = 1.0;

  // Feature statistics
  final Map<String, FeatureStats> _featureStats = {}; // final eklendi ve tip FeatureStats olarak değiştirildi

  void fitFeatures(List<Map<String, dynamic>> data) {
    try {
      _featureStats.clear();

      // Calculate statistics for each feature
      for (var record in data) {
        record.forEach((feature, value) {
          if (value is num) {
            _featureStats.putIfAbsent(
                feature,
                    () => FeatureStats()
            ).addValue(value.toDouble());
          }
        });
      }

      // Finalize statistics calculations
      _featureStats.forEach((_, stats) => stats.calculateStats());
    } catch (e, stackTrace) {
      _logger.error(
          'Error fitting features',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Map<String, double> normalize(
      Map<String, dynamic> features,
      NormalizationType type
      ) {
    try {
      final normalizedFeatures = <String, double>{};

      features.forEach((feature, value) {
        if (value is num && _featureStats.containsKey(feature)) {
          final stats = _featureStats[feature]!;
          normalizedFeatures[feature] = type.normalize(
              value.toDouble(),
              stats
          );
        }
      });

      return normalizedFeatures;
    } catch (e, stackTrace) {
      _logger.error(
          'Error normalizing features',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Map<String, double> denormalize(
      Map<String, double> normalizedFeatures,
      NormalizationType type
      ) {
    try {
      final denormalizedFeatures = <String, double>{};

      normalizedFeatures.forEach((feature, value) {
        if (_featureStats.containsKey(feature)) {
          final stats = _featureStats[feature]!;
          denormalizedFeatures[feature] = type.denormalize(
              value,
              stats
          );
        }
      });

      return denormalizedFeatures;
    } catch (e, stackTrace) {
      _logger.error(
          'Error denormalizing features',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Map<String, FeatureStats> get featureStats =>
      Map.unmodifiable(_featureStats);
}

class FeatureStats {
  double min = double.infinity;
  double max = double.negativeInfinity;
  double sum = 0.0;
  double sumSquared = 0.0;
  int count = 0;
  double mean = 0.0;
  double stdDev = 0.0;

  void addValue(double value) {
    min = math.min(min, value);
    max = math.max(max, value);
    sum += value;
    sumSquared += value * value;
    count++;
  }

  void calculateStats() {
    if (count > 0) {
      mean = sum / count;
      final variance = (sumSquared / count) - (mean * mean);
      stdDev = math.sqrt(variance);
    }
  }
}

abstract class NormalizationType {
  double normalize(double value, FeatureStats stats);
  double denormalize(double normalizedValue, FeatureStats stats);

  static final minMax = MinMaxNormalization();
  static final zScore = ZScoreNormalization();
  static final robust = RobustNormalization();
}

class MinMaxNormalization extends NormalizationType {
  @override
  double normalize(double value, FeatureStats stats) {
    if (stats.max == stats.min) return 0.0;
    return (value - stats.min) / (stats.max - stats.min);
  }

  @override
  double denormalize(double normalizedValue, FeatureStats stats) {
    return normalizedValue * (stats.max - stats.min) + stats.min;
  }
}

class ZScoreNormalization extends NormalizationType {
  @override
  double normalize(double value, FeatureStats stats) {
    if (stats.stdDev == 0) return 0.0;
    return (value - stats.mean) / stats.stdDev;
  }

  @override
  double denormalize(double normalizedValue, FeatureStats stats) {
    return normalizedValue * stats.stdDev + stats.mean;
  }
}

class RobustNormalization extends NormalizationType {
  @override
  double normalize(double value, FeatureStats stats) {
    final iqr = stats.max - stats.min;
    if (iqr == 0) return 0.0;
    return (value - stats.min) / iqr;
  }

  @override
  double denormalize(double normalizedValue, FeatureStats stats) {
    final iqr = stats.max - stats.min;
    return normalizedValue * iqr + stats.min;
  }
}
