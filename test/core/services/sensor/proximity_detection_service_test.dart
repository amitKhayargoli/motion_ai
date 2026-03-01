import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/core/services/sensor/proximity_detection_service.dart';

void main() {
  late ProximityDetectionService service;

  setUp(() {
    service = ProximityDetectionService();
  });

  tearDown(() {
    service.stopListening();
  });

  group('ProximityDetectionService initial state', () {
    test('isListening is false initially', () {
      expect(service.isListening, false);
    });

    test('stopListening can be called safely when not listening', () {
      service.stopListening();
      expect(service.isListening, false);
    });

    test('stopListening is idempotent', () {
      service.stopListening();
      service.stopListening();
      expect(service.isListening, false);
    });
  });

  group('ProximityDetectionService gesture detection logic', () {
    test('brief near-then-far does NOT trigger callback', () {
      int triggerCount = 0;
      final callback = () => triggerCount++;

      // Simulate a quick near event (< 600ms threshold)
      service.processEventForTesting(1, callback); // near
      service.processEventForTesting(0, callback); // far immediately

      expect(triggerCount, 0);
    });

    test('sustained near then far DOES trigger callback', () {
      int triggerCount = 0;
      final callback = () => triggerCount++;

      // First near event
      service.processEventForTesting(1, callback);

      // Simulate time passing by backdating the near start time
      service.setNearStartTimeForTesting(
        DateTime.now().subtract(const Duration(milliseconds: 700)),
      );

      // Another near event to mark _nearHeld = true
      service.processEventForTesting(1, callback);

      // Now far — should trigger
      service.processEventForTesting(0, callback);

      expect(triggerCount, 1);
    });

    test('sustained near without far does NOT trigger (pocket scenario)', () {
      int triggerCount = 0;
      final callback = () => triggerCount++;

      // First near
      service.processEventForTesting(1, callback);

      // Backdate so threshold is exceeded
      service.setNearStartTimeForTesting(
        DateTime.now().subtract(const Duration(seconds: 2)),
      );

      // More near events but never far
      service.processEventForTesting(1, callback);
      service.processEventForTesting(1, callback);
      service.processEventForTesting(1, callback);

      expect(triggerCount, 0);
    });

    test('cooldown prevents second trigger within 5 seconds', () {
      int triggerCount = 0;
      final callback = () => triggerCount++;

      // First gesture: sustained near then far
      service.processEventForTesting(1, callback);
      service.setNearStartTimeForTesting(
        DateTime.now().subtract(const Duration(milliseconds: 700)),
      );
      service.processEventForTesting(1, callback);
      service.processEventForTesting(0, callback);
      expect(triggerCount, 1);

      // Second gesture immediately — should be blocked by cooldown
      service.processEventForTesting(1, callback);
      service.setNearStartTimeForTesting(
        DateTime.now().subtract(const Duration(milliseconds: 700)),
      );
      service.processEventForTesting(1, callback);
      service.processEventForTesting(0, callback);

      expect(triggerCount, 1); // Still 1, second gesture blocked
    });

    test('gesture after cooldown period succeeds', () {
      int triggerCount = 0;
      final callback = () => triggerCount++;

      // First gesture
      service.processEventForTesting(1, callback);
      service.setNearStartTimeForTesting(
        DateTime.now().subtract(const Duration(milliseconds: 700)),
      );
      service.processEventForTesting(1, callback);
      service.processEventForTesting(0, callback);
      expect(triggerCount, 1);

      // Simulate cooldown expiry by backdating the last trigger time
      service.setLastTriggerTimeForTesting(
        DateTime.now().subtract(const Duration(seconds: 6)),
      );

      // Second gesture — should succeed
      service.processEventForTesting(1, callback);
      service.setNearStartTimeForTesting(
        DateTime.now().subtract(const Duration(milliseconds: 700)),
      );
      service.processEventForTesting(1, callback);
      service.processEventForTesting(0, callback);

      expect(triggerCount, 2);
    });
  });
}
