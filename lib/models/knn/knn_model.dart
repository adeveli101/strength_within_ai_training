import 'dart:math' as math;
import '../../core/logger.dart';
import '../../core/exceptions.dart';

class KNNModel {
  final AILogger _logger = AILogger();
  final int k;
  final List<List<double>> _features;
  final List<dynamic> _labels;

  KNNModel({
    required List<List<double>> features,
    required List<dynamic> labels,
    this.k = 3,
  }) : _features = features,
        _labels = labels {
    if (features.length != labels.length) {
      throw ModelTrainingException('Features and labels must have same length');
    }
  }

  Future<void> updateData(List<List<double>> newFeatures, List<dynamic> newLabels) async {
    try {
      if (newFeatures.isEmpty || newLabels.isEmpty || newFeatures.length != newLabels.length) {
        throw ModelTrainingException('Invalid update data');
      }
      _features.addAll(newFeatures);
      _labels.addAll(newLabels);
      _logger.info('Model updated with ${newFeatures.length} new samples');
    } catch (e, stackTrace) {
      _logger.error('Error updating model data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<dynamic> predict(List<double> newFeature) async {
    try {
      if (_features.isEmpty) {
        throw ModelPredictionException('Model has no training data');
      }
      final neighbors = await _findNearestNeighbors(newFeature);
      return _aggregateNeighbors(neighbors);
    } catch (e, stackTrace) {
      _logger.error('Error in prediction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<int>> _findNearestNeighbors(List<double> newFeature) async {
    final distances = <double>[];
    for (var feature in _features) {
      distances.add(_calculateDistance(newFeature, feature));
    }
    return List.generate(distances.length, (i) => i)
      ..sort((a, b) => distances[a].compareTo(distances[b]))
      ..take(k)
          .toList();
  }

  double _calculateDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ModelPredictionException('Feature dimensions mismatch');
    }
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += math.pow(a[i] - b[i], 2);
    }
    return math.sqrt(sum);
  }

  dynamic _aggregateNeighbors(List<int> neighbors) {
    if (_labels[0] is num) {
      return _calculateMean(neighbors);
    }
    return _findMostFrequent(neighbors);
  }

  double _calculateMean(List<int> indices) {
    double sum = 0;
    for (var idx in indices) {
      sum += _labels[idx] as num;
    }
    return sum / indices.length;
  }

  dynamic _findMostFrequent(List<int> indices) {
    final counts = <dynamic, int>{};
    for (var idx in indices) {
      counts[_labels[idx]] = (counts[_labels[idx]] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Map<String, dynamic> toJson() {
    return {
      'k': k,
      'features': _features,
      'labels': _labels,
    };
  }
}
