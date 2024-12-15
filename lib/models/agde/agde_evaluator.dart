import 'dart:math' as math;
import '../../core/exceptions.dart';
import '../../core/logger.dart';
import 'agde_model.dart';

class AGDEEvaluator {
  final AILogger _logger = AILogger();
  final AGDEModel _model;

  AGDEEvaluator(this._model);

  Future<Map<String, double>> evaluate(List<Map<String, dynamic>> features, List<double> labels) async {
    try {
      if (features.isEmpty || labels.isEmpty || features.length != labels.length) {
        throw ModelEvaluationException('Invalid evaluation data');
      }

      List<double> predictions = [];
      for (var feature in features) {
        predictions.add(_model.predict(feature));
      }

      return {
        'mse': _calculateMSE(predictions, labels),
        'mae': _calculateMAE(predictions, labels),
        'r2': _calculateR2(predictions, labels),
      };
    } catch (e, stackTrace) {
      _logger.error('Error in AGDE evaluation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  double _calculateMSE(List<double> predictions, List<double> labels) {
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += math.pow(predictions[i] - labels[i], 2);
    }
    return sum / predictions.length;
  }

  double _calculateMAE(List<double> predictions, List<double> labels) {
    double sum = 0;
    for (int i = 0; i < predictions.length; i++) {
      sum += (predictions[i] - labels[i]).abs();
    }
    return sum / predictions.length;
  }

  double _calculateR2(List<double> predictions, List<double> labels) {
    double labelMean = labels.reduce((a, b) => a + b).toDouble() / labels.length;
    double totalSS = labels
        .map((label) => math.pow(label - labelMean, 2))
        .reduce((a, b) => a + b)
        .toDouble();
    double residualSS = 0;
    for (int i = 0; i < predictions.length; i++) {
      residualSS += math.pow(labels[i] - predictions[i], 2);
    }
    return 1 - (residualSS / totalSS);
  }

  Future<Map<String, double>> crossValidate(List<Map<String, dynamic>> features, List<double> labels, int folds) async {
    try {
      if (features.length != labels.length || folds <= 1) {
        throw ModelEvaluationException('Invalid cross-validation parameters');
      }

      List<Map<String, double>> metrics = [];
      int foldSize = features.length ~/ folds;

      for (int i = 0; i < folds; i++) {
        int validationStart = i * foldSize;
        int validationEnd = (i == folds - 1) ? features.length : (i + 1) * foldSize;

        var trainFeatures = [...features.sublist(0, validationStart), ...features.sublist(validationEnd)];
        var trainLabels = [...labels.sublist(0, validationStart), ...labels.sublist(validationEnd)];
        var validFeatures = features.sublist(validationStart, validationEnd);
        var validLabels = labels.sublist(validationStart, validationEnd);

        await _model.train(trainFeatures, trainLabels);
        var evalMetrics = await evaluate(validFeatures, validLabels);
        metrics.add(evalMetrics);
      }

      return _averageMetrics(metrics);
    } catch (e, stackTrace) {
      _logger.error('Error in AGDE cross-validation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Map<String, double> _averageMetrics(List<Map<String, double>> metrics) {
    Map<String, double> avgMetrics = {};
    for (var metric in metrics[0].keys) {
      avgMetrics[metric] = metrics
          .map((m) => m[metric] ?? 0.0)
          .reduce((a, b) => a + b) / metrics.length;
    }
    return avgMetrics;
  }
}
