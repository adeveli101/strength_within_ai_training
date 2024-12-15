import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceChart extends StatelessWidget {
  final List<Map<String, double>> timeSeriesData;
  final List<String> metrics;

  const PerformanceChart({
    super.key,
    required this.timeSeriesData,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: _createLineBarsData(),
        ),
      ),
    );
  }

  List<LineChartBarData> _createLineBarsData() {
    return metrics.map((metric) {
      final spots = timeSeriesData.asMap().entries.map((entry) {
        return FlSpot(
          entry.key.toDouble(),
          entry.value[metric] ?? 0.0,
        );
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }
}
