import 'dart:developer' as developer;

class Logger {
  static const String _name = 'Metriagro';

  static void debug(String message, {String? tag}) {
    developer.log(message, name: _name, level: 500, time: DateTime.now());
  }

  static void info(String message, {String? tag}) {
    developer.log(message, name: _name, level: 800, time: DateTime.now());
  }

  static void warning(String message, {String? tag}) {
    developer.log(message, name: _name, level: 900, time: DateTime.now());
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: _name, level: 1000, time: DateTime.now(), error: error, stackTrace: stackTrace);
  }
}
