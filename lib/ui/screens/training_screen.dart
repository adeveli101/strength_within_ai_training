import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../models/agde/agde_model.dart';
import '../../models/agde/agde_trainer.dart';
import '../widgets/metrics_card.dart';
import '../widgets/performance_chart.dart';


class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final AILogger _logger = AILogger();
  final AGDETrainer _trainer = AGDETrainer(AGDEModel());
  bool _isTraining = false;
  final List<Map<String, double>> _trainingHistory = [];
  final Map<String, double> _currentMetrics = {
    'accuracy': 0.0,
    'loss': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Training')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AGDE Model Training',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            MetricsCard(
              title: 'Current Metrics',
              metrics: _currentMetrics,
              showTrend: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Training Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            PerformanceChart(
              timeSeriesData: _trainingHistory,
              metrics: ['accuracy', 'loss'],
            ),
            const SizedBox(height: 24),
            _buildTrainingButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingButton() {
    return ElevatedButton(
      onPressed: _isTraining ? null : _startTraining,
      child: Text(_isTraining ? 'Training...' : 'Start Training'),
    );
  }

  Future<void> _startTraining() async {
    setState(() {
      _isTraining = true;
      _trainingHistory.clear();
    });

    try {
      await _trainer.train(
        _generateTrainingFeatures(),
        _generateTrainingLabels(),
        batchSize: AIModelConstants.BATCH_SIZE,
        epochs: AIModelConstants.MAX_EPOCHS,
        validationSplit: AIModelConstants.VALIDATION_SPLIT,
      );
    } catch (e, stackTrace) {
      _logger.error('Error during training', error: e, stackTrace: stackTrace);
    } finally {
      setState(() {
        _isTraining = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateTrainingFeatures() {
    return List.generate(
      1000,
          (index) => {
        'feature1': index.toDouble(),
        'feature2': index * 2.0,
        'feature3': index * 3.0,
      },
    );
  }

  List<double> _generateTrainingLabels() {
    return List.generate(1000, (index) => index % 2 == 0 ? 1.0 : 0.0);
  }
}
