class AIModelConstants {
  // Model parametreleri
  static const int BATCH_SIZE = 32;
  static const double LEARNING_RATE = 0.001;
  static const int MAX_EPOCHS = 100;
  static const double VALIDATION_SPLIT = 0.2;

  // Feature limitleri
  static const int MIN_REPS = 1;
  static const int MAX_REPS = 30;
  static const int MIN_SETS = 1;
  static const int MAX_SETS = 10;

  // Zorluk seviyeleri
  static const Map<String, int> DIFFICULTY_LEVELS = {
    'Beginner': 1,
    'Intermediate': 2,
    'Advanced': 3,
    'Expert': 4
  };
}

class DatasetPaths {
  static const String TOP_50_EXERCISES = 'assets/datasets/Best 50 Exercise for your body';
  static const String GYM_EXERCISES = 'assets/datasets/gym_exercise_dataset';
  static const String GYM_MEMBERS = 'assets/datasets/gym_members_dataset';
}

class ModelMetrics {
  static const List<String> EVALUATION_METRICS = [
    'accuracy',
    'precision',
    'recall',
    'f1_score',
    'mae',
    'rmse'
  ];
}
