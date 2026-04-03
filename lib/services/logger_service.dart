/// Внутренний логгер для отладки прямо в приложении

import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime time;
  final String level;
  final String message;

  LogEntry({
    required this.time,
    required this.level,
    required this.message,
  });

  String get formatted =>
      '[${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}] '
      '[$level] $message';
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final List<LogEntry> _logs = [];
  static const int maxLogs = 100;

  final ValueNotifier<List<LogEntry>> logsNotifier =
      ValueNotifier([]);

  void log(String message, {String level = 'INFO'}) {
    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      message: message,
    );
    _logs.add(entry);
    if (_logs.length > maxLogs) _logs.removeAt(0);
    logsNotifier.value = List.from(_logs);
    debugPrint(entry.formatted);
  }

  void info(String message) => log(message, level: 'INFO');
  void error(String message) => log(message, level: 'ERROR');
  void warn(String message) => log(message, level: 'WARN');

  List<LogEntry> get logs => List.from(_logs);
  void clear() {
    _logs.clear();
    logsNotifier.value = [];
  }
}

// Глобальный инстанс
final logger = LoggerService();
