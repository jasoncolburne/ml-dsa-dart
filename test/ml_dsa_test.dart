import 'dart:convert';
import 'dart:typed_data';

import 'package:ml_dsa/ml_dsa.dart';
import 'package:test/test.dart';

bool testMLDSARoundTrip(ParameterSet parameters) {
  final dsa = MLDSA(parameters);

  final message = utf8.encode("hello world");
  final ctx = Uint8List.fromList([0, 1, 2, 3]);

  final (pk, sk) = dsa.keyGen();
  final sig = dsa.sign(sk, message, ctx);
  return dsa.verify(pk, message, sig, ctx);
}

void main() {
  group('Round Trip', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('ML-DSA-44', () {
      final params = MLDSA44Parameters();
      expect(testMLDSARoundTrip(params), true);
    });

    test('ML-DSA-65', () {
      final params = MLDSA65Parameters();
      expect(testMLDSARoundTrip(params), true);
    });

    test('ML-DSA-87', () {
      final params = MLDSA87Parameters();
      expect(testMLDSARoundTrip(params), true);
    });
  });
}
