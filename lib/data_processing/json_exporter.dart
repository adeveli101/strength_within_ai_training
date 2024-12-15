import 'dart:convert';
import 'dart:io';
import '../core/exceptions.dart';
import '../core/logger.dart';

class JsonExporter {
  final AILogger _logger = AILogger();

  Future<void> exportToJson({
    required dynamic data,
    required String outputPath,
    bool prettyPrint = true,
    String filePrefix = '',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final jsonData = _prepareJsonData(data, metadata);
      final encoder = JsonEncoder.withIndent(prettyPrint ? '  ' : null);

      final fileName = _generateFileName(outputPath, filePrefix);
      final file = File(fileName);

      await file.writeAsString(encoder.convert(jsonData));

      _logger.info('Data exported successfully to: $fileName');
    } catch (e, stackTrace) {
      _logger.error(
          'Error exporting data to JSON',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Map<String, dynamic> _prepareJsonData(
      dynamic data,
      Map<String, dynamic>? metadata
      ) {
    final exportData = <String, dynamic>{
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (metadata != null) {
      exportData['metadata'] = metadata;
    }

    return exportData;
  }

  String _generateFileName(String outputPath, String prefix) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final fileName = '${prefix.isEmpty ? '' : '${prefix}_'}$timestamp.json';
    return '$outputPath/$fileName';
  }

  Future<Map<String, dynamic>> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw DatasetException(
            'JSON file not found: $filePath',
            code: 'FILE_NOT_FOUND'
        );
      }

      final jsonString = await file.readAsString();
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      _logger.error(
          'Error importing data from JSON',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<void> mergeJsonFiles({
    required List<String> inputPaths,
    required String outputPath,
    required String mergeKey,
  }) async {
    try {
      final mergedData = <String, dynamic>{};

      for (final path in inputPaths) {
        final jsonData = await importFromJson(path);
        _mergeJson(mergedData, jsonData, mergeKey);
      }

      await exportToJson(
          data: mergedData,
          outputPath: outputPath,
          filePrefix: 'merged'
      );
    } catch (e, stackTrace) {
      _logger.error(
          'Error merging JSON files',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  void _mergeJson(
      Map<String, dynamic> target,
      Map<String, dynamic> source,
      String mergeKey
      ) {
    source.forEach((key, value) {
      if (!target.containsKey(key)) {
        target[key] = value;
      } else if (target[key] is Map && value is Map) {
        _mergeJson(
            target[key] as Map<String, dynamic>,
            value as Map<String, dynamic>,
            mergeKey
        );
      } else if (target[key] is List && value is List) {
        target[key] = _mergeLists(
            target[key] as List,
            value,
            mergeKey
        );
      }
    });
  }

  List<dynamic> _mergeLists(
      List<dynamic> target,
      List<dynamic> source,
      String mergeKey
      ) {
    final merged = List<dynamic>.from(target);

    for (final item in source) {
      if (item is Map && item.containsKey(mergeKey)) {
        final existingItem = merged.firstWhere(
                (e) => e is Map && e[mergeKey] == item[mergeKey],
            orElse: () => null
        );

        if (existingItem != null) {
          final index = merged.indexOf(existingItem);
          merged[index] = item;
        } else {
          merged.add(item);
        }
      } else if (!merged.contains(item)) {
        merged.add(item);
      }
    }

    return merged;
  }
}
