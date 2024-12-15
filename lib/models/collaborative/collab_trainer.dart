import '../../core/logger.dart';
import 'collab_model.dart';

class CollabTrainer {
  final AILogger _logger = AILogger();
  final CollabModel _model;

  CollabTrainer(this._model);

  Future<void> train(Map<String, Map<String, double>> userItemMatrix) async {
    try {
      _model.userItemMatrix = Map.from(userItemMatrix);
      await _model.calculateSimilarity();
      _logger.info('Model training completed');
    } catch (e, stackTrace) {
      _logger.error('Error training model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateModel(Map<String, Map<String, double>> newUserItemData) async {
    try {
      for (final entry in newUserItemData.entries) {
        if (!_model.userItemMatrix.containsKey(entry.key)) {
          _model.userItemMatrix[entry.key] = {};
        }
        _model.userItemMatrix[entry.key]!.addAll(entry.value);
      }
      await _model.calculateSimilarity();
      _logger.info('Model updated with new data');
    } catch (e, stackTrace) {
      _logger.error('Error updating model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
