import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/core/services/sensor/proximity_wave_service.dart';

void main() {
  late ProximityWaveService service;

  setUp(() {
    service = ProximityWaveService();
  });

  tearDown(() {
    service.stopListening();
  });

  group('ProximityWaveService initial state', () {
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
}
