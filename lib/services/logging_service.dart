import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  static const String _tag = 'EdgeSync';
  
  // Metrics tracking
  Map<String, DateTime> _operationStartTimes = {};
  Map<String, List<Duration>> _operationDurations = {};
  Map<String, int> _errorCounts = {};

  void debug(String message, {String? operation}) {
    _log(LogLevel.debug, message, operation: operation);
  }

  void info(String message, {String? operation}) {
    _log(LogLevel.info, message, operation: operation);
  }

  void warning(String message, {String? operation}) {
    _log(LogLevel.warning, message, operation: operation);
  }

  void error(String message, {String? operation, Object? error}) {
    _log(LogLevel.error, message, operation: operation, error: error);
    if (operation != null) {
      _errorCounts[operation] = (_errorCounts[operation] ?? 0) + 1;
    }
  }

  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    info('Started operation: $operationName', operation: operationName);
  }

  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] ??= [];
      _operationDurations[operationName]!.add(duration);
      
      info('Completed operation: $operationName in ${duration.inMilliseconds}ms', 
           operation: operationName);
      
      _operationStartTimes.remove(operationName);
    }
  }

  Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};
    
    // Add average durations
    _operationDurations.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        final avgMs = durations
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b) / durations.length;
        metrics['${operation}_avg_ms'] = avgMs.round();
        metrics['${operation}_count'] = durations.length;
      }
    });
    
    // Add error counts
    _errorCounts.forEach((operation, count) {
      metrics['${operation}_errors'] = count;
    });
    
    return metrics;
  }

  void _log(LogLevel level, String message, {String? operation, Object? error}) {
    final timestamp = DateTime.now().toIso8601String();
    final operationPrefix = operation != null ? '[$operation] ' : '';
    final logMessage = '$timestamp [$_tag] ${level.name.toUpperCase()}: $operationPrefix$message';
    
    // Use developer.log for better debugging in production
    developer.log(
      logMessage,
      name: _tag,
      level: _getLevelValue(level),
      error: error,
    );
  }

  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

// Global logger instance
final logger = LoggingService();
