import 'dart:convert';
import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'package:ml_dsa/ml_dsa.dart';
import 'package:test/test.dart';

import 'kat_MLDSA_44_det_pure.dart';
import 'kat_MLDSA_65_det_pure.dart';
import 'kat_MLDSA_87_det_pure.dart';

bool testMKDSAKAT(ParameterSet params, List<Map<String, String>> katVectors) {
  final dsa = MLDSA(params);

  for (final vector in katVectors) {
    final seed = Uint8List.fromList(HEX.decode(vector['Seed']!));
    final (pk, sk) = dsa.keyGenWithSeed(seed);

    if (vector['PublicKey'] != HEX.encode(pk)) {
      print('bad pk:');
      print(HEX.encode(pk));
      print('expected:');
      print(vector['PublicKey']);
      return false;
    }

    if (vector['PrivateKey'] != HEX.encode(sk)) {
      print('bad sk:');
      print(HEX.encode(sk));
      print('expected:');
      print(vector['PrivateKey']);
      return false;
    }

    final message = Uint8List.fromList(HEX.decode(vector['Message']!));
    final ctx = Uint8List.fromList(HEX.decode(vector['Context']!));

    final sig = dsa.signDeterministically(sk, message, ctx);
    final List<int> sm = List.generate(sig.length, (int i) => sig[i]);
    sm.addAll(message);
    
    if (vector['Signature'] != HEX.encode(Uint8List.fromList(sm))) {
      print('bad sm:');
      print(HEX.encode(sm));
      print('expected:');
      print(vector['Signature']);
      return false;
    }
  }

  return true;
}

bool testMLDSARoundTrip(ParameterSet parameters, int skLen, int pkLen, int sigLen) {
  final dsa = MLDSA(parameters);

  final message = utf8.encode("hello world");
  final ctx = Uint8List.fromList([0, 1, 2, 3]);

  final (pk, sk) = dsa.keyGen();

  if (pkLen != pk.length) {
    print('unexpected pk length: ${pk.length}');
    return false;
  }

  if (skLen != sk.length) {
    print('unexpected sk length: ${sk.length}');
    return false;
  }

  final sig = dsa.sign(sk, message, ctx);

  if (sigLen != sig.length) {
    print('unexpected sk length: ${sig.length}');
    return false;
  }

  return dsa.verify(pk, message, sig, ctx);
}

void main() {
  group('KAT Vectors: ', () {
    test('ML-DSA-44', () {
      final params = MLDSA44Parameters();
      expect(testMKDSAKAT(params, ML_DSA_44_TestVectors), true);
    });

    test('ML-DSA-65', () {
      final params = MLDSA65Parameters();
      expect(testMKDSAKAT(params, ML_DSA_65_TestVectors), true);
    });

    test('ML-DSA-87', () {
      final params = MLDSA87Parameters();
      expect(testMKDSAKAT(params, ML_DSA_87_TestVectors), true);
    });
  });
  group('Round Trip: ', () {
    test('ML-DSA-44', () {
      final params = MLDSA44Parameters();
      expect(testMLDSARoundTrip(params, 2560, 1312, 2420), true);
    });

    test('ML-DSA-65', () {
      final params = MLDSA65Parameters();
      expect(testMLDSARoundTrip(params, 4032, 1952, 3309), true);
    });

    test('ML-DSA-87', () {
      final params = MLDSA87Parameters();
      expect(testMLDSARoundTrip(params, 4896, 2592, 4627), true);
    });
  });
}
