import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? extras;

  const PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    this.extras,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration': duration.inMicroseconds,
    'timestamp': timestamp.toIso8601String(),
    if (extras != null) 'extras': extras,
  };
}

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  static PerformanceMonitor get instance => _instance;

  PerformanceMonitor._internal();

  final _traces = <String, Stopwatch>{};
  final _metrics = Queue<PerformanceMetric>();
  final _maxMetrics = 1000; // Keep last 1000 metrics
  bool _isMonitoring = false;

  // Frame timing
  Duration _lastFrameTime = Duration.zero;
  int _slowFrameCount = 0;
  int _totalFrameCount = 0;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Monitor frame timing
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        _processFrameTiming(timing);
      }
    });
  }

  void _processFrameTiming(FrameTiming timing) {
    final microseconds = timing.totalSpan.inMicroseconds;
    _lastFrameTime = Duration(microseconds: microseconds);
    _totalFrameCount++;

    // A frame taking more than 16ms is considered slow (targeting 60fps)
    if (microseconds > 16000) {
      // 16ms in microseconds
      _slowFrameCount++;
      _addMetric(
        name: 'slow_frame',
        duration: _lastFrameTime,
        extras: {'build_time': timing.buildDuration.inMicroseconds},
      );
    }
  }

  void startTrace(String name) {
    _traces[name] = Stopwatch()..start();
  }

  void endTrace(String name) {
    final stopwatch = _traces.remove(name);
    if (stopwatch != null) {
      stopwatch.stop();
      _addMetric(name: name, duration: stopwatch.elapsed);
    }
  }

  void _addMetric({
    required String name,
    required Duration duration,
    Map<String, dynamic>? extras,
  }) {
    _metrics.add(
      PerformanceMetric(
        name: name,
        duration: duration,
        timestamp: DateTime.now(),
        extras: extras,
      ),
    );

    // Keep queue size in check
    while (_metrics.length > _maxMetrics) {
      _metrics.removeFirst();
    }

    // Log in debug mode
    if (kDebugMode) {
      print('Performance: $name took ${duration.inMilliseconds}ms');
      if (extras != null) {
        print('Extras: $extras');
      }
    }
  }

  // Performance stats
  double get slowFramePercentage =>
      _totalFrameCount == 0 ? 0 : (_slowFrameCount / _totalFrameCount) * 100;

  Duration get lastFrameTime => _lastFrameTime;

  List<PerformanceMetric> getMetrics({String? filterByName}) {
    if (filterByName != null) {
      return _metrics.where((m) => m.name == filterByName).toList();
    }
    return _metrics.toList();
  }

  void clearMetrics() {
    _metrics.clear();
    _slowFrameCount = 0;
    _totalFrameCount = 0;
  }

  void dispose() {
    _isMonitoring = false;
    clearMetrics();
  }
}
