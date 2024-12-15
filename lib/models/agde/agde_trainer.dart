import 'dart:math' as math;
import '../../core/exceptions.dart';
import '../../core/logger.dart';
import '../../data_processing/feature_normalizer.dart';
import 'agde_model.dart';

class AGDETrainer {
  final AILogger _logger = AILogger();
  final AGDEModel _model;
  final FeatureNormalizer _normalizer = FeatureNormalizer();

  AGDETrainer(this._model);

  Future<void> train(List<Map<String, dynamic>> features, List<double> labels, {
    int batchSize = 32,
    int epochs = 100,
    double validationSplit = 0.2,
  }) async {
    try {
      if (features.isEmpty || labels.isEmpty || features.length != labels.length) {
        throw ModelTrainingException('Invalid training data');
      }

      _normalizer.fitFeatures(features);
      final normalizedFeatures = features.map((f) => _normalizer.normalize(f, NormalizationType.minMax)).toList();

      final splitIndex = (normalizedFeatures.length * (1 - validationSplit)).round();
      final trainFeatures = normalizedFeatures.sublist(0, splitIndex);
      final trainLabels = labels.sublist(0, splitIndex);
      final validFeatures = normalizedFeatures.sublist(splitIndex);
      final validLabels = labels.sublist(splitIndex);

      for (int epoch = 0; epoch < epochs; epoch++) {
        double trainLoss = await _trainEpoch(trainFeatures, trainLabels, batchSize);
        double validLoss = _calculateValidationLoss(validFeatures, validLabels);

        if (epoch % 10 == 0) {
          _logger.info('Epoch $epoch, Train Loss: $trainLoss, Validation Loss: $validLoss');
        }

        if (_shouldEarlyStop(validLoss)) {
          _logger.info('Early stopping at epoch $epoch');
          break;
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error in AGDE training', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<double> _trainEpoch(List<Map<String, double>> features, List<double> labels, int batchSize) async {
    double totalLoss = 0;
    for (int i = 0; i < features.length; i += batchSize) {
      final batchEnd = (i + batchSize < features.length) ? i + batchSize : features.length;
      final batchFeatures = features.sublist(i, batchEnd);
      final batchLabels = labels.sublist(i, batchEnd);

      totalLoss += await _model.trainOnBatch(batchFeatures, batchLabels);
    }
    return totalLoss / features.length;
  }

  double _calculateValidationLoss(List<Map<String, double>> features, List<double> labels) {
    double totalLoss = 0;
    for (int i = 0; i < features.length; i++) {
      final prediction = _model.predict(features[i]);
      totalLoss += math.pow(prediction - labels[i], 2);
    }
    return totalLoss / features.length;
  }

  bool _shouldEarlyStop(double validationLoss) {
    // TODO: Implement early stopping logic
    return false;
  }
}
