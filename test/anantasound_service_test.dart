import 'package:flutter_test/flutter_test.dart';
import 'package:mbharata_client/core/services/anantasound_service.dart';

void main() {
  group('AnantaSoundService Tests', () {
    late AnantaSoundService service;

    setUp(() {
      service = AnantaSoundService.instance;
    });

    tearDown(() {
      service.dispose();
    });

    test('should create quantum sound field', () {
      final position = SphericalCoord(
        r: 5.0,
        theta: pi / 4,
        phi: pi / 2,
        height: 2.0,
      );

      final field = service.createQuantumSoundField(
        440.0,
        position,
        QuantumSoundState.coherent,
      );

      expect(field.frequency, equals(440.0));
      expect(field.position, equals(position));
      expect(field.quantumState, equals(QuantumSoundState.coherent));
      expect(field.amplitude.real, equals(1.0));
      expect(field.amplitude.imaginary, equals(0.0));
    });

    test('should calculate interference correctly', () {
      final center = SphericalCoord(
        r: 5.0,
        theta: pi / 2,
        phi: 0.0,
        height: 0.0,
      );

      final field = InterferenceField(
        type: InterferenceFieldType.constructive,
        center: center,
        fieldRadius: 3.0,
        sourceFields: [],
        entangledPairs: [],
      );

      final position = SphericalCoord(
        r: 6.0,
        theta: pi / 2,
        phi: 0.0,
        height: 0.0,
      );

      final interference = field.calculateInterference(position, 0.0);
      expect(interference.real, equals(0.0));
      expect(interference.imaginary, equals(0.0));
    });

    test('should create quantum superposition', () {
      final center = SphericalCoord(
        r: 5.0,
        theta: pi / 2,
        phi: 0.0,
        height: 0.0,
      );

      final field = InterferenceField(
        type: InterferenceFieldType.constructive,
        center: center,
        fieldRadius: 3.0,
        sourceFields: [],
        entangledPairs: [],
      );

      final fields = [
        QuantumSoundField(
          amplitude: const Complex(1.0, 0.0),
          frequency: 440.0,
          phase: 0.0,
          quantumState: QuantumSoundState.coherent,
          position: center,
          timestamp: DateTime.now(),
        ),
        QuantumSoundField(
          amplitude: const Complex(0.5, 0.5),
          frequency: 880.0,
          phase: pi / 4,
          quantumState: QuantumSoundState.coherent,
          position: center,
          timestamp: DateTime.now(),
        ),
      ];

      final superposition = field.quantumSuperposition(fields);
      expect(superposition.quantumState, equals(QuantumSoundState.superposition));
      expect(superposition.frequency, equals(660.0)); // (440 + 880) / 2
    });

    test('should calculate dome eigen frequencies', () {
      final frequencies = DomeAcousticResonator.calculateEigenFrequencies(10.0, 5.0);
      expect(frequencies, isNotEmpty);
      expect(frequencies.first, greaterThan(0.0));
    });

    test('should calculate reverb time', () {
      final resonator = DomeAcousticResonator(
        domeRadius: 10.0,
        domeHeight: 5.0,
        resonantFrequencies: [440.0, 880.0],
        acousticProperties: {440.0: 1.0, 880.0: 0.8},
      );

      final rt60 = resonator.calculateReverbTime(440.0);
      expect(rt60, greaterThan(0.0));
    });

    test('should handle complex number operations', () {
      const c1 = Complex(1.0, 2.0);
      const c2 = Complex(3.0, 4.0);

      final sum = c1 + c2;
      expect(sum.real, equals(4.0));
      expect(sum.imaginary, equals(6.0));

      final product = c1 * c2;
      expect(product.real, equals(-5.0)); // 1*3 - 2*4
      expect(product.imaginary, equals(10.0)); // 1*4 + 2*3

      expect(c1.magnitude, closeTo(2.236, 0.001));
      expect(c1.phase, closeTo(1.107, 0.001));
    });

    test('should process sound field', () {
      final position = SphericalCoord(
        r: 5.0,
        theta: pi / 4,
        phi: pi / 2,
        height: 2.0,
      );

      final field = QuantumSoundField(
        amplitude: const Complex(1.0, 0.0),
        frequency: 440.0,
        phase: 0.0,
        quantumState: QuantumSoundState.coherent,
        position: position,
        timestamp: DateTime.now(),
      );

      service.processSoundField(field);
      final outputFields = service.getOutputFields();
      expect(outputFields, isNotEmpty);
    });

    test('should get system statistics', () {
      final stats = service.getStatistics();
      expect(stats, isA<SystemStatistics>());
      expect(stats.activeFields, isA<int>());
      expect(stats.entangledPairs, isA<int>());
      expect(stats.coherenceRatio, isA<double>());
      expect(stats.energyEfficiency, isA<double>());
      expect(stats.qrdConnected, isA<bool>());
      expect(stats.mechanicalDevicesActive, isA<int>());
    });

    test('should set quantum uncertainty', () {
      service.setQuantumUncertainty(0.5);
      expect(service.quantumUncertainty, equals(0.5));

      service.setQuantumUncertainty(1.5); // Should be clamped to 1.0
      expect(service.quantumUncertainty, equals(1.0));

      service.setQuantumUncertainty(-0.5); // Should be clamped to 0.0
      expect(service.quantumUncertainty, equals(0.0));
    });

    test('should add and remove interference fields', () {
      final center = SphericalCoord(
        r: 5.0,
        theta: pi / 2,
        phi: 0.0,
        height: 0.0,
      );

      final field = InterferenceField(
        type: InterferenceFieldType.constructive,
        center: center,
        fieldRadius: 3.0,
        sourceFields: [],
        entangledPairs: [],
      );

      service.addInterferenceField(field);
      service.removeInterferenceField(0);
    });

    test('should update system', () {
      service.update(0.016); // ~60 FPS
      // Should not throw any exceptions
    });
  });

  group('Complex Number Tests', () {
    test('should perform basic operations', () {
      const c1 = Complex(3.0, 4.0);
      const c2 = Complex(1.0, 2.0);

      final sum = c1 + c2;
      expect(sum.real, equals(4.0));
      expect(sum.imaginary, equals(6.0));

      final diff = c1 - c2;
      expect(diff.real, equals(2.0));
      expect(diff.imaginary, equals(2.0));

      final product = c1 * c2;
      expect(product.real, equals(-5.0));
      expect(product.imaginary, equals(10.0));

      final quotient = c1 / c2;
      expect(quotient.real, closeTo(2.2, 0.1));
      expect(quotient.imaginary, closeTo(-0.4, 0.1));
    });

    test('should calculate magnitude and phase', () {
      const c = Complex(3.0, 4.0);
      expect(c.magnitude, equals(5.0));
      expect(c.phase, closeTo(0.927, 0.001));
    });
  });

  group('SphericalCoord Tests', () {
    test('should create and access coordinates', () {
      const coord = SphericalCoord(
        r: 5.0,
        theta: pi / 4,
        phi: pi / 2,
        height: 2.0,
      );

      expect(coord.r, equals(5.0));
      expect(coord.theta, equals(pi / 4));
      expect(coord.phi, equals(pi / 2));
      expect(coord.height, equals(2.0));
    });

    test('should convert to and from JSON', () {
      const coord = SphericalCoord(
        r: 5.0,
        theta: pi / 4,
        phi: pi / 2,
        height: 2.0,
      );

      final json = coord.toJson();
      final restored = SphericalCoord.fromJson(json);

      expect(restored.r, equals(coord.r));
      expect(restored.theta, equals(coord.theta));
      expect(restored.phi, equals(coord.phi));
      expect(restored.height, equals(coord.height));
    });
  });

  group('QuantumSoundField Tests', () {
    test('should create and access field properties', () {
      const position = SphericalCoord(
        r: 5.0,
        theta: pi / 4,
        phi: pi / 2,
        height: 2.0,
      );

      final field = QuantumSoundField(
        amplitude: const Complex(1.0, 0.5),
        frequency: 440.0,
        phase: pi / 4,
        quantumState: QuantumSoundState.superposition,
        position: position,
        timestamp: DateTime.now(),
      );

      expect(field.amplitude.real, equals(1.0));
      expect(field.amplitude.imaginary, equals(0.5));
      expect(field.frequency, equals(440.0));
      expect(field.phase, equals(pi / 4));
      expect(field.quantumState, equals(QuantumSoundState.superposition));
      expect(field.position, equals(position));
    });

    test('should convert to and from JSON', () {
      const position = SphericalCoord(
        r: 5.0,
        theta: pi / 4,
        phi: pi / 2,
        height: 2.0,
      );

      final field = QuantumSoundField(
        amplitude: const Complex(1.0, 0.5),
        frequency: 440.0,
        phase: pi / 4,
        quantumState: QuantumSoundState.superposition,
        position: position,
        timestamp: DateTime.now(),
      );

      final json = field.toJson();
      final restored = QuantumSoundField.fromJson(json);

      expect(restored.amplitude.real, equals(field.amplitude.real));
      expect(restored.amplitude.imaginary, equals(field.amplitude.imaginary));
      expect(restored.frequency, equals(field.frequency));
      expect(restored.phase, equals(field.phase));
      expect(restored.quantumState, equals(field.quantumState));
      expect(restored.position.r, equals(field.position.r));
    });
  });
}

