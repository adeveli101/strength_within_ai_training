import '../../core/logger.dart';
// ignore: unused_import
import '../../core/exceptions.dart';
import '../../core/constants.dart';
import '../data_processing/csv_loader.dart';
import '../data_processing/feature_normalizer.dart';
import '../data_processing/json_exporter.dart';

// Interface for communication with main project
abstract class UserProfileInterface {
  Map<String, dynamic> toFeatures();
  String getId();
  Map<String, dynamic> getPreferences();
}

class ScenarioRunner {
  final AILogger _logger = AILogger();
  final CSVLoader _csvLoader = CSVLoader();
  final FeatureNormalizer _normalizer = FeatureNormalizer();
  final JsonExporter _exporter = JsonExporter();

  Future<Map<String, dynamic>> runScenario({
    required String scenarioName,
    required UserProfileInterface userProfile,
    required List<dynamic> models,
    String? customDatasetPath,
  }) async {
    try {
      // Load and prepare data
      final dataset = await _loadDataset(customDatasetPath);
      final userFeatures = await _prepareUserFeatures(userProfile, dataset);

      final results = <String, dynamic>{};

      // Run scenario for each model
      for (final model in models) {
        final modelResults = await _runModelScenario(
          model: model,
          userFeatures: userFeatures,
          dataset: dataset,
          userProfile: userProfile,
        );
        results[model.runtimeType.toString()] = modelResults;
      }

      // Export results
      await _exportResults(scenarioName, results, userProfile);

      return {
        'scenario_name': scenarioName,
        'user_id': userProfile.getId(),
        'results': results,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      _logger.error('Error running scenario', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadDataset(String? customPath) async {
    final path = customPath ?? DatasetPaths.TOP_50_EXERCISES;
    return await _csvLoader.loadExerciseDataset(path: path);
  }

  Future<Map<String, dynamic>> _prepareUserFeatures(
      UserProfileInterface profile,
      List<Map<String, dynamic>> dataset,
      ) async {
    final rawFeatures = profile.toFeatures();
    return _normalizer.normalize(rawFeatures, NormalizationType.minMax);
  }

  Future<Map<String, dynamic>> _runModelScenario({
    required dynamic model,
    required Map<String, dynamic> userFeatures,
    required List<Map<String, dynamic>> dataset,
    required UserProfileInterface userProfile,
  }) async {
    try {
      final preferences = userProfile.getPreferences();
      // ignore: unused_local_variable
      final modelMetrics = ModelMetrics.EVALUATION_METRICS;

      // Split dataset for training and validation
      final splitIndex = (dataset.length * AIModelConstants.VALIDATION_SPLIT).round();
      final trainData = dataset.sublist(0, splitIndex);
      final validData = dataset.sublist(splitIndex);

      // Train and evaluate model
      await model.train(trainData);
      final predictions = await model.predict(userFeatures);
      final metrics = await model.evaluate(validData);

      return {
        'predictions': predictions,
        'metrics': metrics,
        'user_preferences_match': _calculatePreferenceMatch(
          predictions,
          preferences,
        ),
      };
    } catch (e, stackTrace) {
      _logger.error('Error in model scenario', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  double _calculatePreferenceMatch(
      List<dynamic> predictions,
      Map<String, dynamic> preferences,
      ) {
    // Implement preference matching logic
    return 0.0;
  }

  Future<void> _exportResults(
      String scenarioName,
      Map<String, dynamic> results,
      UserProfileInterface userProfile,
      ) async {
    await _exporter.exportToJson(
      data: results,
      outputPath: 'results/$scenarioName',
      filePrefix: userProfile.getId(),
      metadata: {
        'user_id': userProfile.getId(),
        'scenario': scenarioName,
      },
    );
  }
}
