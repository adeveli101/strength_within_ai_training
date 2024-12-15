import '../../core/exceptions.dart';
import '../../core/logger.dart';
import '../../data_processing/feature_normalizer.dart';

class AGDEModel {
  final AILogger _logger = AILogger();
  final FeatureNormalizer _normalizer = FeatureNormalizer();
  late List<double> _weights;
  double _bias = 0.0;  // Initialize with default value instead of using late
  final double _learningRate;
  final int _epochs;

  AGDEModel({
    double learningRate = 0.01,
    int epochs = 100,
  }) : _learningRate = learningRate,
        _epochs = epochs;


  Future<double> trainOnBatch(List<Map<String, double>> batchFeatures, List<double> batchLabels) async {
    double totalLoss = 0;
    for (int i = 0; i < batchFeatures.length; i++) {
      final prediction = _predict(batchFeatures[i]);
      final loss = prediction - batchLabels[i];
      totalLoss += loss * loss;

      _updateWeights(batchFeatures[i], loss);
      _bias -= _learningRate * loss;
    }
    return totalLoss / batchFeatures.length;
  }


  Future<void> train(List<Map<String, dynamic>> features, List<double> labels) async {
    try {
      if (features.isEmpty || labels.isEmpty || features.length != labels.length) {
        throw ModelTrainingException('Invalid training data');
      }

      _normalizer.fitFeatures(features);
      final normalizedFeatures = features.map((f) => _normalizer.normalize(f, NormalizationType.minMax)).toList();

      _initializeWeights(normalizedFeatures[0].length);

      for (int epoch = 0; epoch < _epochs; epoch++) {
        double totalLoss = 0;
        for (int i = 0; i < normalizedFeatures.length; i++) {
          final prediction = _predict(normalizedFeatures[i]);
          final loss = prediction - labels[i];
          totalLoss += loss * loss;

          _updateWeights(normalizedFeatures[i], loss);
          _bias -= _learningRate * loss;
        }

        if (epoch % 10 == 0) {
          _logger.info('Epoch $epoch, Loss: ${totalLoss / normalizedFeatures.length}');
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error training AGDE model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  double predict(Map<String, dynamic> features) {
    try {
      final normalizedFeatures = _normalizer.normalize(features, NormalizationType.minMax);
      return _predict(normalizedFeatures);
    } catch (e, stackTrace) {
      _logger.error('Error predicting with AGDE model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void _initializeWeights(int featureCount) {
    _weights = List.filled(featureCount, 0.0);
    _bias = 0.0;
  }

  double _predict(Map<String, double> normalizedFeatures) {
    double sum = _bias;
    normalizedFeatures.forEach((feature, value) {
      final index = _weights.length - normalizedFeatures.length + normalizedFeatures.keys.toList().indexOf(feature);
      sum += _weights[index] * value;
    });
    return sum;
  }

  void _updateWeights(Map<String, double> features, double error) {
    for (int i = 0; i < _weights.length; i++) {
      final feature = features.keys.elementAt(i);
      _weights[i] -= _learningRate * error * features[feature]!;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'weights': _weights,
      'bias': _bias,
      'learning_rate': _learningRate,
      'epochs': _epochs,
      'normalizer_stats': _normalizer.featureStats,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _weights = List<double>.from(json['weights']);
    _bias = json['bias'];
    // Normalizer stats yüklemesi burada yapılabilir
  }
}
