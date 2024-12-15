import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../models/knn/knn_model.dart';
import '../../testing/model_tester.dart';
import '../widgets/metrics_card.dart';
import '../widgets/performance_chart.dart';


class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  EvaluationScreenState createState() => EvaluationScreenState();
}

class EvaluationScreenState extends State<EvaluationScreen> {
  final AILogger _logger = AILogger();
  final ModelTester _modelTester = ModelTester();
  Map<String, dynamic> _evaluationResults = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _evaluateModel();
  }

  Future<void> _evaluateModel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final model = KNNModel(features: [], labels: [], k: 5);
      final results = await _modelTester.testModel(
        model: model,
        trainFeatures: _generateTrainFeatures(),
        trainLabels: _generateTrainLabels(),
        testFeatures: _generateTestFeatures(),
        testLabels: _generateTestLabels(),
      );

      setState(() {
        _evaluationResults = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.error('Error evaluating model', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<List<double>> _generateTrainFeatures() {
    // Implement actual train feature generation
    return List.generate(200, (index) => List.generate(5, (i) => index.toDouble() + i));
  }

  List<dynamic> _generateTrainLabels() {
    // Implement actual train label generation
    return List.generate(200, (index) => index % 2 == 0);
  }

  List<List<double>> _generateTestFeatures() {
    // Implement actual test feature generation
    return List.generate(50, (index) => List.generate(5, (i) => index.toDouble() + i + 0.5));
  }

  List<dynamic> _generateTestLabels() {
    // Implement actual test label generation
    return List.generate(50, (index) => index % 2 == 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Model Evaluation')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model: ${_evaluationResults['model_type'] ?? 'N/A'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 24),
              Text(
                'Test Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              MetricsCard(
                title: 'Performance Metrics',
                metrics: _evaluationResults['test_results'] ?? {},
              ),
              SizedBox(height: 24),
              Text(
                'Cross-Validation Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              MetricsCard(
                title: 'Average Metrics',
                metrics: _evaluationResults['cross_validation_results'] ?? {},
              ),
              SizedBox(height: 24),
              Text(
                'Performance Over Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              PerformanceChart(
                timeSeriesData: _generateTimeSeriesData(),
                metrics: ['accuracy', 'loss'],
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
        'accuracy': 0.6 + index * 0.04,
        'loss': 0.8 - index * 0.08,
      },
    );
  }
}
