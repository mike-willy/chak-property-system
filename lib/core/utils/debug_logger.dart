import 'package:flutter/foundation.dart';

class DebugLogger extends ChangeNotifier {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final List<String> _logs = [];
  bool _isVisible = false;

  List<String> get logs => List.unmodifiable(_logs);
  bool get isVisible => _isVisible;

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final logMessage = '[$timestamp] $message';
    _logs.add(logMessage);
    if (_logs.length > 100) {
      _logs.removeAt(0); // Keep last 100 logs
    }
    notifyListeners();
    if (kDebugMode) {
      print('[DebugLogger] $message');
    }
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }
}
