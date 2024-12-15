import 'dart:async';
import '../../core/logger.dart';
import '../../core/exceptions.dart';
import '../models/knn/knn_model.dart';
import '../models/agde/agde_model.dart';
import '../models/collaborative/collab_model.dart';
import '../models/knn/knn_evaluator.dart';
import '../models/agde/agde_evaluator.dart';
import '../models/collaborative/collab_evaluator.dart';
import '../data_processing/feature_normalizer.dart';
import '../data_processing/json_exporter.dart';

class ABTestRunner {
  final AILogger _logger = AILogger();
  final FeatureNormalizer _normalizer = FeatureNormalizer();
  final JsonExporter _exporter = JsonExporter();

  Future<Map<String, dynamic>> runABTest({
    required dynamic modelA,
    required dynamic modelB,
    required List<dynamic> testFeatures,
    required List<dynamic> testLabels,
    String outputPath = 'results/ab_test',
  }) async {
    try {
      final normalizedFeatures = await _normalizeFeatures(testFeatures);
      final resultsA = await _evaluateModel(modelA, normalizedFeatures, testLabels);
      final resultsB = await _evaluateModel(modelB, normalizedFeatures, testLabels);

      final winner = _determineWinner(resultsA, resultsB);
      final results = {
        'modelA': resultsA,
        'modelB': resultsB,
        'winner': winner,
        'improvement': _calculateImprovement(resultsA, resultsB),
      };

      await _exportResults(results, outputPath);

      return results;
    } catch (e, stackTrace) {
      _logger.error('Error running AB test', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<dynamic>> _normalizeFeatures(List<dynamic> features) async {
    if (features.isEmpty) return [];
    if (features[0] is List<double>) {
      return features;
    } else if (features[0] is Map<String, dynamic>) {
      return features.map((f) => _normalizer.normalize(f, NormalizationType.minMax)).toList();
    } else {
      throw Exception('Unsupported feature type');
    }
  }


  Future<Map<String, double>> _evaluateModel(dynamic model, List<dynamic> features, List<dynamic> labels) async {
    if (model is KNNModel) {
      return await KNNEvaluator(model).evaluate(features as List<List<double>>, labels);
    } else if (model is AGDEModel) {
      return await AGDEEvaluator(model).evaluate(features as List<Map<String, dynamic>>, labels as List<double>);
    } else if (model is CollabModel) {
      return await CollabEvaluator(model).evaluate(features as Map<String, Set<String>>);
    } else {
      throw ModelEvaluationException('Unsupported model type');
    }
  }

  String _determineWinner(Map<String, double> resultsA, Map<String, double> resultsB) {
    final metrics = ['accuracy', 'precision', 'recall', 'f1_score'];
    int winsA = 0, winsB = 0;

    for (var metric in metrics) {
      if ((resultsA[metric] ?? 0) > (resultsB[metric] ?? 0)) {
        winsA++;
      } else if ((resultsA[metric] ?? 0) < (resultsB[metric] ?? 0)) {
        winsB++;
      }
    }

    return winsA > winsB ? 'A' : (winsB > winsA ? 'B' : 'Tie');
  }

  Map<String, double> _calculateImprovement(Map<String, double> resultsA, Map<String, double> resultsB) {
    final improvements = <String, double>{};
    resultsA.forEach((metric, valueA) {
      final valueB = resultsB[metric] ?? 0;
      improvements[metric] = ((valueB - valueA) / valueA * 100).abs();
    });
    return improvements;
  }

  Future<void> _exportResults(Map<String, dynamic> results, String outputPath) async {
    await _exporter.exportToJson(
      data: results,
      outputPath: outputPath,
      filePrefix: 'ab_test_results',
    );
  }
}