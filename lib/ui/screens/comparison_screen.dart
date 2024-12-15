import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../models/agde/agde_model.dart';
import '../../models/collaborative/collab_model.dart';
import '../../models/knn/knn_model.dart';
import '../../testing/ab_test_runner.dart';
import '../widgets/model_comparison.dart';
import '../widgets/performance_chart.dart';


class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ComparisonScreenState createState() => ComparisonScreenState();
}

class ComparisonScreenState extends State<ComparisonScreen> {
  final AILogger _logger = AILogger();
  final ABTestRunner _abTestRunner = ABTestRunner();
  Map<String, dynamic> _results = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runComparison();
  }

  Future<void> _runComparison() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final knnModel = KNNModel(features: [], labels: [], k: 5);
      final agdeModel = AGDEModel();

      final results = await _abTestRunner.runABTest(
        modelA: knnModel,
        modelB: agdeModel,
        testFeatures: _generateTestFeatures(),
        testLabels: _generateTestLabels(),
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.error('Error running comparison', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<List<double>> _generateTestFeatures() {
    return List.generate(100, (index) => List.generate(5, (i) => (index + i).toDouble()));
  }

  List<dynamic> _generateTestLabels() {
    return List.generate(100, (index) => index % 2 == 0);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Model Comparison')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? Center(child: Text('No comparison results available'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A/B Test Results',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              ModelComparison(
                modelResults: [_results['modelA'], _results['modelB']],
                metrics: ['accuracy', 'precision', 'recall', 'f1_score'],
              ),
              SizedBox(height: 24),
              Text(
                'Performance Comparison',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              PerformanceChart(
                timeSeriesData: _generateTimeSeriesData(),
                metrics: ['accuracy', 'loss'],
              ),
              SizedBox(height: 24),
              Text(
                'Winner: ${_results['winner'] ?? 'N/A'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Text(
                'Improvement: ${_formatImprovement(_results['improvement'])}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, double>> _generateTimeSeriesData() {
    // Implement actual time series data generation
    return List.generate(
      10,
          (index) => {
        'accuracy': 0.5 + index * 0.05,
        'loss': 1.0 - index * 0.1,
      },
    );
  }

  String _formatImprovement(Map<String, double>? improvement) {
    if (improvement == null) return 'N/A';
    return improvement.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}%')
        .join(', ');
  }
}
