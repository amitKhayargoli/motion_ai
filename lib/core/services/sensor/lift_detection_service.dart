import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef OnLiftDetected = void Function();

class LiftDetectionService {
  static const double _tiltThresholdDeg = 25.0;
  static const double _magnitudeDeviationThreshold = 2.0;
  static const double _gravity = 9.80665;
  static const Duration _debounceDuration = Duration(milliseconds: 800);
  static const int _calibrationSampleCount = 10;

  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _debounceTimer;
  bool _isMonitoring = false;

  double? _baselineTiltDeg;
  final List<double> _calibrationSamples = [];

  bool get isMonitoring => _isMonitoring;

  void startMonitoring({required OnLiftDetected onLiftDetected}) {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _baselineTiltDeg = null;
    _calibrationSamples.clear();

    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((event) {
      final tilt = _computeTilt(event.x, event.y, event.z);

      // Calibration phase: collect baseline readings
      if (_baselineTiltDeg == null) {
        _calibrationSamples.add(tilt);
        if (_calibrationSamples.length >= _calibrationSampleCount) {
          _baselineTiltDeg = _calibrationSamples.reduce((a, b) => a + b) /
              _calibrationSamples.length;
        }
        return;
      }

      _processEvent(event.x, event.y, event.z, tilt, onLiftDetected);
    });
  }

  double _computeTilt(double x, double y, double z) {
    final horizontal = sqrt(x * x + y * y);
    return atan2(horizontal, z) * (180.0 / pi);
  }

  void _processEvent(
    double x,
    double y,
    double z,
    double tiltDeg,
    OnLiftDetected callback,
  ) {
    final tiltDelta = (tiltDeg - _baselineTiltDeg!).abs();

    final magnitude = sqrt(x * x + y * y + z * z);
    final magnitudeDeviation = (magnitude - _gravity).abs();

    final tiltTriggered = tiltDelta >= _tiltThresholdDeg;
    final motionDetected = magnitudeDeviation > _magnitudeDeviationThreshold;

    if (tiltTriggered && motionDetected) {
      // Both conditions met — start debounce (or keep running)
      _debounceTimer ??= Timer(_debounceDuration, () {
        if (_isMonitoring) {
          callback();
          stopMonitoring();
        }
      });
    } else if (!tiltTriggered) {
      // Tilt returned to baseline — was a bump, not a lift; cancel debounce
      _debounceTimer?.cancel();
      _debounceTimer = null;
    }
    // If tilt is still elevated but magnitude normalised (phone held still
    // at a new angle after being lifted), keep the debounce timer running.
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _subscription?.cancel();
    _subscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _baselineTiltDeg = null;
    _calibrationSamples.clear();
  }
}

final liftDetectionServiceProvider = Provider<LiftDetectionService>((ref) {
  final service = LiftDetectionService();
  ref.onDispose(() => service.stopMonitoring());
  return service;
});
