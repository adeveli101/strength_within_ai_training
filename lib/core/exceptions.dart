abstract class AIException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  AIException(this.message, {
    required this.code,
    this.details,
  });

  @override
  String toString() => 'AIException($code): $message';
}

class DatasetException extends AIException {
  DatasetException(super.message, {super.code = 'DATASET_ERROR', super.details});
}

class ModelTrainingException extends AIException {
  ModelTrainingException(super.message, {super.code = 'TRAINING_ERROR', super.details});
}

class PredictionException extends AIException {
  PredictionException(super.message, {super.code = 'PREDICTION_ERROR', super.details});
}

class FeatureExtractionException extends AIException {
  FeatureExtractionException(super.message, {super.code = 'FEATURE_ERROR', super.details});
}
class ModelEvaluationException extends AIException {
  ModelEvaluationException(super.message, {String? code, super.details})
      : super(code: code ?? 'EVALUATION_ERROR');
}
class ModelPredictionException extends AIException {
  ModelPredictionException(super.message, {String? code, super.details})
      : super(code: code ?? 'PREDICTION_ERROR');
}
