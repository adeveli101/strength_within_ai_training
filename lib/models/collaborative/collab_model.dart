import 'dart:math' as math;
import '../../core/logger.dart';
import '../../core/exceptions.dart';

class CollabModel {
  final AILogger _logger = AILogger();
  Map<String, Map<String, double>> userItemMatrix = {};
  List<List<double>>? similarityMatrix;


  Future<void> train(Map<String, Map<String, double>> userItemMatrix) async {
    try {
      this.userItemMatrix = Map.from(userItemMatrix);
      await calculateSimilarity();
      _logger.info('Model training completed');
    } catch (e, stackTrace) {
      _logger.error('Error training model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> calculateSimilarity() async {
    try {
      final userIds = userItemMatrix.keys.toList();
      final itemIds = _getAllItems();

      // Kullanıcı-öğe matrisini oluştur
      List<List<double>> matrix = List.generate(
          userIds.length,
              (i) => List.generate(itemIds.length, (j) {
            final userId = userIds[i];
            final itemId = itemIds.toList()[j];
            return userItemMatrix[userId]?[itemId] ?? 0.0;
          })
      );

      // Kosinüs benzerliği hesapla
      similarityMatrix = _calculateCosineSimilarity(matrix);
    } catch (e, stackTrace) {
      _logger.error('Error calculating similarity', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<String>> recommend(String userId, {int numRecommendations = 5}) async {
    try {
      if (similarityMatrix == null) {
        await calculateSimilarity();
      }

      final userIds = userItemMatrix.keys.toList();
      final userIndex = userIds.indexOf(userId);

      if (userIndex == -1) {
        throw ModelPredictionException('User not found');
      }

      final similarities = similarityMatrix![userIndex];
      final recommendations = <String, double>{};

      // En benzer kullanıcıları bul
      final sortedIndices = _getTopIndices(similarities, numRecommendations + 1);

      for (final index in sortedIndices) {
        if (index == userIndex) continue;

        final similarUserId = userIds[index];
        final similarUserItems = userItemMatrix[similarUserId] ?? {};

        for (final entry in similarUserItems.entries) {
          if (!userItemMatrix[userId]!.containsKey(entry.key)) {
            recommendations[entry.key] = (recommendations[entry.key] ?? 0.0) +
                entry.value * similarities[index];
          }
        }
      }

      final sortedRecommendations = recommendations.entries.toList();
      sortedRecommendations.sort((a, b) => b.value.compareTo(a.value));

      return sortedRecommendations
          .take(numRecommendations)
          .map((e) => e.key)
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Error generating recommendations', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Set<String> _getAllItems() {
    return userItemMatrix.values
        .expand((items) => items.keys)
        .toSet();
  }

  List<List<double>> _calculateCosineSimilarity(List<List<double>> matrix) {
    final int n = matrix.length;
    final similarity = List.generate(
        n,
            (i) => List.generate(n, (j) {
          if (i == j) return 1.0;
          return _cosine(matrix[i], matrix[j]);
        })
    );
    return similarity;
  }

  double _cosine(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  List<int> _getTopIndices(List<double> values, int n) {
    return List.generate(values.length, (i) => i)
      ..sort((a, b) => values[b].compareTo(values[a]))
      ..take(n)
          .toList();
  }
}
