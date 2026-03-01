import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

typedef OnProximityCoverDetected = void Function();

class ProximityDetectionService {
  // --- Configuration constants ---
  /// Minimum duration the sensor must report "near" before qualifying.
  static const Duration _nearDurationThreshold = Duration(milliseconds: 600);

  /// Cooldown after a successful trigger to ignore further gestures.
  static const Duration _cooldownDuration = Duration(seconds: 5);

  // --- Internal state ---
  StreamSubscription<dynamic>? _subscription;
  bool _isListening = false;
  DateTime? _nearStartTime;
  bool _nearHeld = false;
  DateTime? _lastTriggerTime;

  bool get isListening => _isListening;

  void startListening({
    required OnProximityCoverDetected onCoverDetected,
  }) {
    if (_isListening) return;
    _isListening = true;
    _nearStartTime = null;
    _nearHeld = false;

    try {
      _subscription = ProximitySensor.events.listen(
        (int proximityValue) {
          _processEvent(proximityValue, onCoverDetected);
        },
        onError: (error) {
          debugPrint('Proximity sensor error: $error');
          stopListening();
        },
      );
    } catch (e) {
      debugPrint('Proximity sensor unavailable: $e');
      _isListening = false;
    }
  }

  void _processEvent(
    int proximityValue,
    OnProximityCoverDetected callback,
  ) {
    final bool isNear = proximityValue > 0;
    final now = DateTime.now();

    // Cooldown guard
    if (_lastTriggerTime != null &&
        now.difference(_lastTriggerTime!) < _cooldownDuration) {
      return;
    }

    if (isNear) {
      // Object detected near the sensor
      _nearStartTime ??= now;

      // Check if held long enough
      if (!_nearHeld &&
          now.difference(_nearStartTime!) >= _nearDurationThreshold) {
        _nearHeld = true;
      }
    } else {
      // Object moved away ("far")
      if (_nearHeld) {
        // The full "cover then uncover" gesture is complete
        _nearHeld = false;
        _nearStartTime = null;
        _lastTriggerTime = now;
        callback();
      } else {
        // Too brief — reset
        _nearStartTime = null;
      }
    }
  }

  /// Exposed for testing only.
  @visibleForTesting
  void processEventForTesting(
    int proximityValue,
    OnProximityCoverDetected callback,
  ) {
    _processEvent(proximityValue, callback);
  }

  /// Exposed for testing only — override the internal near-start time.
  @visibleForTesting
  void setNearStartTimeForTesting(DateTime? time) {
    _nearStartTime = time;
  }

  /// Exposed for testing only — override the last trigger time.
  @visibleForTesting
  void setLastTriggerTimeForTesting(DateTime? time) {
    _lastTriggerTime = time;
  }

  void stopListening() {
    _isListening = false;
    _subscription?.cancel();
    _subscription = null;
    _nearStartTime = null;
    _nearHeld = false;
    // Intentionally preserve _lastTriggerTime so cooldown persists across
    // start/stop cycles within the same service instance.
  }
}

final proximityDetectionServiceProvider =
    Provider<ProximityDetectionService>((ref) {
  final service = ProximityDetectionService();
  ref.onDispose(() => service.stopListening());
  return service;
});
