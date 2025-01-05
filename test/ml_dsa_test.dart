import 'package:ml_dsa/ml_dsa.dart';
import 'package:test/test.dart';

void main() {
  group('Round trip', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('ML-DSA-44', () {
      final _ = MLDSA44Parameters();
    });

    test('ML-DSA-65', () {
      final _ = MLDSA65Parameters();
    });

    test('ML-DSA-87', () {
      final _ = MLDSA87Parameters();
    });
  });
}
