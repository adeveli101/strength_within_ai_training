// ignore_for_file: avoid_print

enum LogLevel { debug, info, warning, error }

class AILogger {
  static final AILogger _instance = AILogger._internal();
  factory AILogger() => _instance;
  AILogger._internal();

  final List<LogEntry> _logs = [];
  LogLevel _currentLevel = LogLevel.info;

  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  void debug(String message, {dynamic data}) {
    _log(LogLevel.debug, message, data: data);
  }

  void info(String message, {dynamic data}) {
    _log(LogLevel.info, message, data: data);
  }

  void warning(String message, {dynamic data}) {
    _log(LogLevel.warning, message, data: data);
  }

  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, data: error, stackTrace: stackTrace);
  }

  void _log(LogLevel level, String message, {
    dynamic data,
    StackTrace? stackTrace
  }) {
    if (level.index < _currentLevel.index) return;

    final entry = LogEntry(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        data: data,
        stackTrace: stackTrace
    );

    _logs.add(entry);
    _printLog(entry);
  }

  void _printLog(LogEntry entry) {
    final prefix = '[${entry.level.name.toUpperCase()}]';
    final timestamp = entry.timestamp.toIso8601String();

    print('$prefix $timestamp: ${entry.message}');

    if (entry.data != null) {
      print('Data: ${entry.data}');
    }

    if (entry.stackTrace != null) {
      print('StackTrace: ${entry.stackTrace}');
    }
  }

  List<LogEntry> getLogs() => List.unmodifiable(_logs);

  void clearLogs() => _logs.clear();
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic data;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
    this.stackTrace,
  });
}
