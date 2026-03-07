import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

typedef OnWaveDetected = void Function();

class ProximityWaveService {
  static const Duration _cooldownDuration = Duration(milliseconds: 1500);
  static const Duration _maxNearDuration = Duration(milliseconds: 1200);

  StreamSubscription<int>? _subscription;
  bool _isListening = false;

  bool _isNear = false;
  DateTime? _nearStartTime;
  DateTime? _lastTriggerTime;

  bool get isListening => _isListening;

  void startListening({required OnWaveDetected onWaveDetected}) {
    if (_isListening) return;
    _isListening = true;
    _isNear = false;
    _nearStartTime = null;
    _lastTriggerTime = null;

    _subscription = ProximitySensor.events.listen((int event) {
      _processEvent(event, onWaveDetected);
    });
  }

  void _processEvent(int event, OnWaveDetected callback) {
    final isCurrentlyNear = event > 0;

    if (isCurrentlyNear && !_isNear) {
      // Transition: FAR -> NEAR (hand just covered the sensor)
      _isNear = true;
      _nearStartTime = DateTime.now();
    } else if (!isCurrentlyNear && _isNear) {
      // Transition: NEAR -> FAR (hand moved away — wave completed)
      _isNear = false;

      if (_nearStartTime == null) return;

      final nearDuration = DateTime.now().difference(_nearStartTime!);
      _nearStartTime = null;

      // Reject if sensor was covered too long (phone call / pocket)
      if (nearDuration > _maxNearDuration) return;

      // Reject if still in cooldown from last trigger
      if (_lastTriggerTime != null) {
        final elapsed = DateTime.now().difference(_lastTriggerTime!);
        if (elapsed < _cooldownDuration) return;
      }

      // Valid wave gesture detected
      _lastTriggerTime = DateTime.now();
      callback();
    }
  }

  void stopListening() {
    _isListening = false;
    _subscription?.cancel();
    _subscription = null;
    _isNear = false;
    _nearStartTime = null;
    _lastTriggerTime = null;
  }
}

final proximityWaveServiceProvider = Provider<ProximityWaveService>((ref) {
  final service = ProximityWaveService();
  ref.onDispose(() => service.stopListening());
  return service;
});
