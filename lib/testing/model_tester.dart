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

class ModelTester {
  final AILogger _logger = AILogger();
  final FeatureNormalizer _normalizer = FeatureNormalizer();
  final JsonExporter _exporter = JsonExporter();

  Future<Map<String, dynamic>> testModel({
    required dynamic model,
    required List<dynamic> trainFeatures,
    required List<dynamic> trainLabels,
    required List<dynamic> testFeatures,
    required List<dynamic> testLabels,
    int crossValidationFolds = 5,
    String outputPath = 'results/model_test',
  }) async {
    try {
      final normalizedTrainFeatures = await _normalizeFeatures(trainFeatures);
      final normalizedTestFeatures = await _normalizeFeatures(testFeatures);

      await _trainModel(model, normalizedTrainFeatures, trainLabels);
      final testResults = await _evaluateModel(model, normalizedTestFeatures, testLabels);
      final cvResults = await _crossValidate(model, normalizedTrainFeatures, trainLabels, crossValidationFolds);

      final results = {
        'model_type': model.runtimeType.toString(),
        'test_results': testResults,
        'cross_validation_results': cvResults,
      };

      await _exportResults(results, outputPath);

      return results;
    } catch (e, stackTrace) {
      _logger.error('Error testing model', error: e, stackTrace: stackTrace);
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


  Future<void> _trainModel(dynamic model, List<dynamic> features, List<dynamic> labels) async {
    if (model is KNNModel) {
      await model.updateData(features as List<List<double>>, labels);
    } else if (model is AGDEModel) {
      await model.train(features as List<Map<String, dynamic>>, labels as List<double>);
    } else if (model is CollabModel) {
      await model.train(features as Map<String, Map<String, double>>);
    } else {
      throw ModelTrainingException('Unsupported model type');
    }
  }

  Future<Map<String, double>> _evaluateModel(dynamic model, List<dynamic> features, List<dynamic> labels) async {
    if (model is KNNModel) {
      return await KNNEvaluator(model).evaluate(features as List<List<double>>, labels);
    } else if (model is AGDEModel) {
      return await AGDEEvaluator(model).evaluate(features as List<Map<String, dynamic>>, labels as List<double>);
    } else if (model is CollabModel) {
      // CollabModel için özel bir değerlendirme mantığı eklemeniz gerekebilir
      throw UnimplementedError('CollabModel evaluation not implemented');
    } else {
      throw ModelEvaluationException('Unsupported model type');
    }
  }


  Future<Map<String, double>> _crossValidate(dynamic model, List<dynamic> features, List<dynamic> labels, int folds) async {
    final foldSize = features.length ~/ folds;
    final results = <Map<String, double>>[];

    for (int i = 0; i < folds; i++) {
      final validationStart = i * foldSize;
      final validationEnd = (i == folds - 1) ? features.length : (i + 1) * foldSize;

      final trainFeatures = [...features.sublist(0, validationStart), ...features.sublist(validationEnd)];
      final trainLabels = [...labels.sublist(0, validationStart), ...labels.sublist(validationEnd)];
      final testFeatures = features.sublist(validationStart, validationEnd);
      final testLabels = labels.sublist(validationStart, validationEnd);

      await _trainModel(model, trainFeatures, trainLabels);
      final foldResults = await _evaluateModel(model, testFeatures, testLabels);
      results.add(foldResults);
    }

    return _averageResults(results);
  }

  Map<String, double> _averageResults(List<Map<String, double>> results) {
    final avgResults = <String, double>{};
    for (var metric in results[0].keys) {
      avgResults[metric] = results.map((r) => r[metric]!).reduce((a, b) => a + b) / results.length;
    }
    return avgResults;
  }

  Future<void> _exportResults(Map<String, dynamic> results, String outputPath) async {
    await _exporter.exportToJson(
      data: results,
      outputPath: outputPath,
      filePrefix: 'model_test_results',
    );
  }
}