import '../../core/logger.dart';
import 'knn_model.dart';

class KNNTrainer {
  final AILogger _logger = AILogger();
  final KNNModel _model;

  KNNTrainer(this._model);

  Future<void> train(List<List<double>> features, List<dynamic> labels) async {
    try {
      await _model.updateData(features, labels);
      _logger.info('Model training completed');
    } catch (e, stackTrace) {
      _logger.error('Error training model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateModel(List<List<double>> newFeatures, List<dynamic> newLabels) async {
    try {
      await _model.updateData(newFeatures, newLabels);
      _logger.info('Model updated with new data');
    } catch (e, stackTrace) {
      _logger.error('Error updating model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
