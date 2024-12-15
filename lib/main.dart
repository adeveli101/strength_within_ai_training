import 'package:flutter/material.dart';
import 'core/logger.dart';
import 'ui/screens/training_screen.dart';
import 'ui/screens/evaluation_screen.dart';
import 'ui/screens/comparison_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AILogger().setLogLevel(LogLevel.info);
  runApp(const AITrainingApp());
}

class AITrainingApp extends StatelessWidget {
  const AITrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strength Within AI Training',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AITrainingHome(),
    );
  }
}

class AITrainingHome extends StatefulWidget {
  const AITrainingHome({super.key});

  @override
  State<AITrainingHome> createState() => _AITrainingHomeState();
}

class _AITrainingHomeState extends State<AITrainingHome> {
  int _selectedIndex = 0;
  final AILogger _logger = AILogger();

  final List<Widget> _screens = [
    const TrainingScreen(),
    const EvaluationScreen(),
    const ComparisonScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _logger.info('Navigated to screen index: $index');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Training',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Evaluation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare),
            label: 'Comparison',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
