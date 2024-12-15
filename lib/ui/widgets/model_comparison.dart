import 'package:flutter/material.dart';

class ModelComparison extends StatelessWidget {
  final List<Map<String, dynamic>> modelResults;
  final List<String> metrics;

  const ModelComparison({
    super.key,
    required this.modelResults,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _buildColumns(),
          rows: _buildRows(),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(label: Text('Model')),
      ...metrics.map((metric) => DataColumn(label: Text(metric))),
    ];
  }

  List<DataRow> _buildRows() {
    return modelResults.map((result) {
      return DataRow(
        cells: [
          DataCell(Text(result['model_type'] as String)),
          ...metrics.map((metric) {
            final value = result['metrics']?[metric] as double?;
            return DataCell(
              Text(value?.toStringAsFixed(3) ?? 'N/A'),
            );
          }),
        ],
      );
    }).toList();
  }
}
