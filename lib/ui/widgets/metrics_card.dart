import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  final String title;
  final Map<String, double> metrics;
  final bool showTrend;

  const MetricsCard({
    super.key,
    required this.title,
    required this.metrics,
    this.showTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...metrics.entries.map((entry) => _buildMetricRow(
              context,
              entry.key,
              entry.value,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String name, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Row(
            children: [
              Text(
                value.toStringAsFixed(3),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showTrend) ...[
                const SizedBox(width: 8),
                _buildTrendIndicator(value),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double value) {
    final isPositive = value > 0;
    return Icon(
      isPositive ? Icons.trending_up : Icons.trending_down,
      color: isPositive ? Colors.green : Colors.red,
      size: 20,
    );
  }
}
