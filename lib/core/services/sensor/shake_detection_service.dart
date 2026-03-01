import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef OnShakeDetected = void Function();

class ShakeDetectionService {
  static const double _magnitudeThreshold = 15.0;
  static const int _requiredShakeCount = 2;
  static const Duration _shakeWindow = Duration(milliseconds: 500);
  static const Duration _cooldownDuration = Duration(milliseconds: 1500);

  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _isListening = false;

  final List<DateTime> _shakeTimestamps = [];
  DateTime? _lastTriggerTime;

  bool get isListening => _isListening;

  void startListening({required OnShakeDetected onShakeDetected}) {
    if (_isListening) return;
    _isListening = true;
    _shakeTimestamps.clear();
    _lastTriggerTime = null;

    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((event) {
      _processEvent(event.x, event.y, event.z, onShakeDetected);
    });
  }

  void _processEvent(
    double x,
    double y,
    double z,
    OnShakeDetected callback,
  ) {
    final magnitude = sqrt(x * x + y * y + z * z);

    if (magnitude < _magnitudeThreshold) return;

    // In cooldown period — ignore
    if (_lastTriggerTime != null) {
      final elapsed = DateTime.now().difference(_lastTriggerTime!);
      if (elapsed < _cooldownDuration) return;
    }

    final now = DateTime.now();

    // Prune old timestamps outside the shake window
    _shakeTimestamps.removeWhere(
      (t) => now.difference(t) > _shakeWindow,
    );

    _shakeTimestamps.add(now);

    if (_shakeTimestamps.length >= _requiredShakeCount) {
      _shakeTimestamps.clear();
      _lastTriggerTime = now;
      callback();
    }
  }

  void stopListening() {
    _isListening = false;
    _subscription?.cancel();
    _subscription = null;
    _shakeTimestamps.clear();
    _lastTriggerTime = null;
  }
}

final shakeDetectionServiceProvider = Provider<ShakeDetectionService>((ref) {
  final service = ShakeDetectionService();
  ref.onDispose(() => service.stopListening());
  return service;
});
