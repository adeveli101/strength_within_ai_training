import '../../core/logger.dart';
import 'collab_model.dart';

class CollabEvaluator {
  final AILogger _logger = AILogger();
  final CollabModel _model;

  CollabEvaluator(this._model);

  Future<Map<String, double>> evaluate(Map<String, Set<String>> testData) async {
    try {
      int correctPredictions = 0;
      int totalPredictions = 0;

      for (final entry in testData.entries) {
        if (_model.userItemMatrix.containsKey(entry.key)) {
          final recommendations = await _model.recommend(
              entry.key,
              numRecommendations: entry.value.length
          );

          final correctItems = recommendations.toSet().intersection(entry.value);
          correctPredictions += correctItems.length;
          totalPredictions += entry.value.length;
        }
      }

      final accuracy = totalPredictions > 0 ?
      correctPredictions / totalPredictions : 0.0;

      return {'accuracy': accuracy};
    } catch (e, stackTrace) {
      _logger.error('Error evaluating model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, double>> crossValidate(
      Map<String, Map<String, double>> data, {
        int folds = 5
      }) async {
    try {
      final userIds = data.keys.toList();
      final foldSize = userIds.length ~/ folds;
      final accuracies = <double>[];

      for (int i = 0; i < folds; i++) {
        final validationStart = i * foldSize;
        final validationEnd = i == folds - 1 ? userIds.length : (i + 1) * foldSize;

        final trainData = <String, Map<String, double>>{};
        final testData = <String, Set<String>>{};

        for (int j = 0; j < userIds.length; j++) {
          final userId = userIds[j];
          if (j >= validationStart && j < validationEnd) {
            testData[userId] = data[userId]!.keys.toSet();
          } else {
            trainData[userId] = Map.from(data[userId]!);
          }
        }

        await _model.calculateSimilarity();
        final results = await evaluate(testData);
        accuracies.add(results['accuracy']!);
      }

      return {
        'average_accuracy': accuracies.reduce((a, b) => a + b) / accuracies.length
      };
    } catch (e, stackTrace) {
      _logger.error('Error in cross-validation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
