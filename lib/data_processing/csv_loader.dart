import 'dart:io';
import 'package:csv/csv.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';

class CSVLoader {
  final AILogger _logger = AILogger();
  final CsvToListConverter _converter = const CsvToListConverter();

  Future<List<Map<String, dynamic>>> loadExerciseDataset({
    required String path,
    String delimiter = ',',
    bool hasHeaderRow = true,
    List<String>? requiredColumns,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw DatasetException(
            'CSV file not found: $path',
            code: 'FILE_NOT_FOUND'
        );
      }

      final input = await file.readAsString();
      final rows = _converter.convert(
        input,
        fieldDelimiter: delimiter,
        eol: '\n',
      );

      if (rows.isEmpty) {
        throw DatasetException(
            'CSV file is empty',
            code: 'EMPTY_FILE'
        );
      }

      final headers = hasHeaderRow ?
      List<String>.from(rows.first) :
      List.generate(rows.first.length, (i) => 'column_$i');

      if (requiredColumns != null) {
        _validateRequiredColumns(headers, requiredColumns);
      }

      final data = hasHeaderRow ? rows.skip(1).toList() : rows;
      return _convertToMapList(data, headers);
    } catch (e, stackTrace) {
      _logger.error(
          'Error loading CSV dataset',
          error: e,
          stackTrace: stackTrace
      );
      rethrow;
    }
  }

  void _validateRequiredColumns(
      List<String> headers,
      List<String> requiredColumns
      ) {
    final missingColumns = requiredColumns
        .where((col) => !headers.contains(col))
        .toList();

    if (missingColumns.isNotEmpty) {
      throw DatasetException(
          'Missing required columns: ${missingColumns.join(", ")}',
          code: 'MISSING_COLUMNS'
      );
    }
  }

  List<Map<String, dynamic>> _convertToMapList(
      List<List<dynamic>> rows,
      List<String> headers
      ) {
    return rows.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        if (i < row.length) {
          map[headers[i]] = _parseValue(row[i]);
        }
      }
      return map;
    }).toList();
  }

  dynamic _parseValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    // Try parsing as number
    if (value is String) {
      if (value.contains('.')) {
        return double.tryParse(value);
      }
      return int.tryParse(value) ?? value;
    }

    return value;
  }

  Future<void> validateDataset({
    required String path,
    required Map<String, DataValidator> validators,
  }) async {
    final data = await loadExerciseDataset(path: path);
    final errors = <String>[];

    for (var row in data) {
      validators.forEach((column, validator) {
        if (row.containsKey(column)) {
          final value = row[column];
          if (!validator(value)) {
            errors.add('Invalid value in column $column: $value');
          }
        }
      });
    }

    if (errors.isNotEmpty) {
      throw DatasetException(
          'Dataset validation failed',
          code: 'VALIDATION_ERROR',
          details: errors
      );
    }
  }
}

typedef DataValidator = bool Function(dynamic value);

class DatasetConfig {
  final String path;
  final String delimiter;
  final bool hasHeaderRow;
  final List<String>? requiredColumns;
  final Map<String, DataValidator>? validators;

  const DatasetConfig({
    required this.path,
    this.delimiter = ',',
    this.hasHeaderRow = true,
    this.requiredColumns,
    this.validators,
  });
}
