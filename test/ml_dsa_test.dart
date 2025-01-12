import 'dart:convert';
import 'dart:math';
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
    final Uint8List sm = Uint8List(sig.length + message.length);
    sm.setRange(0, sig.length, sig);
    sm.setRange(sig.length, sm.length, message);

    if (vector['Signature'] != HEX.encode(sm)) {
      print('bad sm (${sig.length}/${sm.length}):');
      print(HEX.encode(sm));
      print('expected:');
      print(vector['Signature']);
      return false;
    }
  }

  return true;
}

bool testMLDSARoundTrip(
  ParameterSet parameters,
  int skLen,
  int pkLen,
  int sigLen,
) {
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

  if (!dsa.verify(pk, message, sig, ctx)) {
    print("verification failed");
    return false;
  }

  final Uint8List pkPrime = mutate(pk);
  final Uint8List messagePrime = mutate(message);
  final Uint8List sigPrime = mutate(sig);
  final Uint8List ctxPrime = mutate(ctx);

  if (dsa.verify(pkPrime, message, sig, ctx)) {
    print("verification SUCCEEDED incorrectly for a mutated pk");
    return false;
  }

  if (dsa.verify(pk, messagePrime, sig, ctx)) {
    print("verification SUCCEEDED incorrectly for a mutated message");
    return false;
  }

  if (dsa.verify(pk, message, sigPrime, ctx)) {
    print("verification SUCCEEDED incorrectly for a mutated signature");
    return false;
  }

  if (dsa.verify(pk, message, sig, ctxPrime)) {
    print("verification SUCCEEDED incorrectly for a mutated context");
    return false;
  }

  return true;
}

Uint8List mutate(Uint8List input) {
  final data = Uint8List.fromList(input);
  final offset = Random.secure().nextInt(data.length);
  data[offset] ^= 0x01;
  return data;
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
