import 'dart:math' as math;
import '../../core/logger.dart';
import 'knn_model.dart';

class KNNEvaluator {
  final AILogger _logger = AILogger();
  final KNNModel _model;

  KNNEvaluator(this._model);

  Future<Map<String, double>> evaluate(
      List<List<double>> testFeatures,
      List<dynamic> testLabels
      ) async {
    try {
      if (testFeatures.isEmpty || testLabels.isEmpty) {
        throw Exception('Empty test data');
      }
      final predictions = <dynamic>[];
      for (var feature in testFeatures) {
        predictions.add(await _model.predict(feature));
      }
      return {
        'accuracy': _calculateAccuracy(predictions, testLabels),
        'mse': _calculateMSE(predictions, testLabels),
        'mae': _calculateMAE(predictions, testLabels)
      };
    } catch (e, stackTrace) {
      _logger.error('Error evaluating model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, double>> crossValidate(
      List<List<double>> features,
      List<dynamic> labels, {
        int folds = 5
      }) async {
    try {
      if (features.length < folds) {
        throw Exception('Not enough samples for $folds-fold cross validation');
      }
      final foldSize = features.length ~/ folds;
      final metrics = <Map<String, double>>[];
      for (int i = 0; i < folds; i++) {
        final validationStart = i * foldSize;
        final validationEnd = i == folds - 1 ? features.length : (i + 1) * foldSize;
        final trainFeatures = [...features.sublist(0, validationStart), ...features.sublist(validationEnd)];
        final trainLabels = [...labels.sublist(0, validationStart), ...labels.sublist(validationEnd)];
        final testFeatures = features.sublist(validationStart, validationEnd);
        final testLabels = labels.sublist(validationStart, validationEnd);
        await _model.updateData(trainFeatures, trainLabels);
        final foldMetrics = await evaluate(testFeatures, testLabels);
        metrics.add(foldMetrics);
      }
      return _averageMetrics(metrics);
    } catch (e, stackTrace) {
      _logger.error('Error in cross-validation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  double _calculateAccuracy(List<dynamic> predictions, List<dynamic> actual) {
    int correct = 0;
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] == actual[i]) correct++;
    }
    return correct / predictions.length;
  }

  double _calculateMSE(List<dynamic> predictions, List<dynamic> actual) {
    if (predictions[0] is! num) return 0.0;
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += math.pow((predictions[i] as num) - (actual[i] as num), 2);
    }
    return sum / predictions.length;
  }

  double _calculateMAE(List<dynamic> predictions, List<dynamic> actual) {
    if (predictions[0] is! num) return 0.0;
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += ((predictions[i] as num) - (actual[i] as num)).abs();
    }
    return sum / predictions.length;
  }

  Map<String, double> _averageMetrics(List<Map<String, double>> metrics) {
    final result = <String, double>{};
    for (var metric in metrics[0].keys) {
      result[metric] = metrics.map((m) => m[metric]!).reduce((a, b) => a + b) / metrics.length;
    }
    return result;
  }
}
