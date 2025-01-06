import 'dart:typed_data';

import 'conversion.dart';
import 'entropy.dart';
import 'expansion.dart';
import 'shake.dart';
import 'ntt.dart';
import 'polynomials.dart';
import 'reduction.dart';

abstract class ParameterSet {
  int q();
  int zeta();
  int d();
  int tau();
  int lambda();
  int gamma1();
  int gamma2();
  int k();
  int l();
  int eta();
  int beta();
  int omega();
}

class MLDSA44Parameters implements ParameterSet {
  @override
  int q() => 8380417;

  @override
  int zeta() => 1753;

  @override
  int d() => 13;

  @override
  int tau() => 39;

  @override
  int lambda() => 128;

  @override
  int gamma1() => 131072;

  @override
  int gamma2() => 95232;

  @override
  int k() => 4;

  @override
  int l() => 4;

  @override
  int eta() => 2;

  @override
  int beta() => 78; // Added implementation for beta

  @override
  int omega() => 80;
}

class MLDSA65Parameters implements ParameterSet {
  @override
  int q() => 8380417;

  @override
  int zeta() => 1753;

  @override
  int d() => 13;

  @override
  int tau() => 49;

  @override
  int lambda() => 192;

  @override
  int gamma1() => 524288;

  @override
  int gamma2() => 261888;

  @override
  int k() => 6;

  @override
  int l() => 5;

  @override
  int eta() => 4;

  @override
  int beta() => 196; // Added implementation for beta

  @override
  int omega() => 55;
}

class MLDSA87Parameters implements ParameterSet {
  @override
  int q() => 8380417;

  @override
  int zeta() => 1753;

  @override
  int d() => 13;

  @override
  int tau() => 60;

  @override
  int lambda() => 256;

  @override
  int gamma1() => 524288;

  @override
  int gamma2() => 261888;

  @override
  int k() => 8;

  @override
  int l() => 7;

  @override
  int eta() => 2;

  @override
  int beta() => 120;

  @override
  int omega() => 75;
}

const seedLength = 32;

class MLDSA {
  ParameterSet parameters;

  MLDSA(this.parameters);

  (Uint8List, Uint8List) keyGen() {
    final rnd = rbg(seedLength);
    return _keyGen(rnd);
  }

  (Uint8List, Uint8List) keyGenWithSeed(Uint8List rnd) {
    return _keyGen(rnd);
  }

  Uint8List sign(Uint8List sk, Uint8List message, Uint8List ctx) {
    if (ctx.length > 255) {
      throw Exception('ctx length > 255');
    }

    final rnd = rbg(seedLength);

    final List<int> mPrime = List.empty(growable: true);
    mPrime.addAll(integerToBytes(0, 1));
    mPrime.addAll(integerToBytes(ctx.length, 1));
    mPrime.addAll(ctx);
    mPrime.addAll(message);

    return _sign(sk, Uint8List.fromList(mPrime), rnd);
  }

  Uint8List signDeterministically(
      Uint8List sk, Uint8List message, Uint8List ctx) {
    if (ctx.length > 255) {
      throw Exception('ctx length > 255');
    }

    final Uint8List rnd = Uint8List.fromList(List.generate(seedLength, (int _) => 0, growable: false));

    final List<int> mPrime = List.empty(growable: true);
    mPrime.addAll(integerToBytes(0, 1));
    mPrime.addAll(integerToBytes(ctx.length, 1));
    mPrime.addAll(ctx);
    mPrime.addAll(message);

    return _sign(sk, Uint8List.fromList(mPrime), rnd);
  }

  bool verify(
      Uint8List pk, Uint8List message, Uint8List signature, Uint8List ctx) {
    if (ctx.length > 255) {
      throw Exception('ctx length > 255');
    }

    final List<int> mPrime = List.empty(growable: true);
    mPrime.addAll(integerToBytes(0, 1));
    mPrime.addAll(integerToBytes(ctx.length, 1));
    mPrime.addAll(ctx);
    mPrime.addAll(message);

    return _verify(pk, Uint8List.fromList(mPrime), signature);
  }

  (Uint8List, Uint8List) _keyGen(Uint8List rnd) {
    final List<int> input = List.generate(rnd.length, (int i) => rnd[i]);
    input.addAll(integerToBytes(parameters.k(), 1));
    input.addAll(integerToBytes(parameters.l(), 1));

    IncrementalSHAKE hasher = IncrementalSHAKE(true);
    hasher.absorb(Uint8List.fromList(input));
    final Uint8List bytes = hasher.squeeze(128);

    final Uint8List rho = bytes.sublist(0, 32);
    final Uint8List rhoPrime = bytes.sublist(32, 96);
    final Uint8List kappa = bytes.sublist(96);

    //ignore: non_constant_identifier_names
    final List<List<List<int>>> AHat = expandA(parameters, rho);
    final (List<List<int>> s1, List<List<int>> s2) =
        expandS(parameters, rhoPrime);
    final List<List<int>> s1Hat = vectorNtt(parameters, s1);

    final List<List<int>> product = matrixVectorNtt(parameters, AHat, s1Hat);

    final List<List<int>> t = List.generate(parameters.k(), (int j) {
      return addPolynomials(
          parameters, nttInverse(parameters, product[j]), s2[j]);
    }, growable: false);

    List<List<int>> t0 = List.generate(
      parameters.k(),
      (int _) => List.generate(256, (int _) => 0, growable: false),
      growable: false,
    );
    List<List<int>> t1 = List.generate(
      parameters.k(),
      (int _) => List.generate(256, (int _) => 0, growable: false),
      growable: false,
    );

    int x, y;
    for (int j = 0; j < parameters.k(); j++) {
      for (int i = 0; i < 256; i++) {
        (x, y) = power2Round(parameters, t[j][i]);
        t1[j][i] = x;
        t0[j][i] = y;
      }
    }

    final Uint8List pk = pkEncode(parameters, rho, t1);

    hasher = IncrementalSHAKE(true);
    hasher.absorb(pk);
    final Uint8List tr = hasher.squeeze(64);
    final Uint8List sk = skEncode(parameters, rho, kappa, tr, s1, s2, t0);

    return (pk, sk);
  }

  Uint8List _sign(Uint8List sk, Uint8List mPrime, Uint8List rnd) {
    final (
      Uint8List rho,
      Uint8List kappa,
      Uint8List tr,
      List<List<int>> s1,
      List<List<int>> s2,
      List<List<int>> t0
    ) = skDecode(parameters, sk);

    final List<List<int>> s1Hat = vectorNtt(parameters, s1);
    final List<List<int>> s2Hat = vectorNtt(parameters, s2);
    final List<List<int>> t0Hat = vectorNtt(parameters, t0);
    // ignore: non_constant_identifier_names
    final List<List<List<int>>> AHat = expandA(parameters, rho);

    List<int> inputHash = List.generate(64, (int i) => tr[i]);
    inputHash.addAll(mPrime);

    IncrementalSHAKE hasher = IncrementalSHAKE(true);
    hasher.absorb(Uint8List.fromList(inputHash));
    final Uint8List mu = hasher.squeeze(64);

    inputHash = List.generate(32, (int i) => kappa[i]);
    inputHash.addAll(rnd);
    inputHash.addAll(mu);

    // important to reset the hasher here
    hasher = IncrementalSHAKE(true);
    hasher.absorb(Uint8List.fromList(inputHash));
    final Uint8List rhoPrimePrime = hasher.squeeze(64);

    // ignore: unused_local_variable
    int k = 0;
    List<List<int>>? z;
    List<List<int>>? h;
    Uint8List cTilde = Uint8List(0);

    while (z == null && h == null) {
      final List<List<int>> y = expandMask(
        parameters,
        rhoPrimePrime,
        k,
      );

      final List<List<int>> yHat = vectorNtt(parameters, y);
      final List<List<int>> product = matrixVectorNtt(parameters, AHat, yHat);

      final List<List<int>> w = List.generate(parameters.k(), (int j) {
        return nttInverse(parameters, product[j]);
      }, growable: false);

      final List<List<int>> w1 = List.generate(parameters.k(), (int j) {
        return List.generate(256, (int i) {
          return highBits(parameters, w[j][i]);
        }, growable: false);
      }, growable: false);

      inputHash = List.generate(64, (int i) => mu[i]);
      inputHash.addAll(w1Encode(parameters, w1));

      IncrementalSHAKE hasher = IncrementalSHAKE(true);
      hasher.absorb(Uint8List.fromList(inputHash));
      cTilde = hasher.squeeze(parameters.lambda() ~/ 4);

      final List<int> c = sampleInBall(parameters, cTilde);
      final List<int> cHat = ntt(parameters, c);

      final List<List<int>> cs1 = vectorNttInverse(
          parameters, scalarVectorNtt(parameters, cHat, s1Hat));
      final List<List<int>> cs2 = vectorNttInverse(
          parameters, scalarVectorNtt(parameters, cHat, s2Hat));

      for (int i = 0; i < cs1.length; i++) {
        for (int j = 0; j < cs1[i].length; j++) {
          cs1[i][j] = modQSymmetric(cs1[i][j], parameters.q());
        }
      }

      z = vectorAddPolynomials(parameters, y, cs1);
      final List<List<int>> r = vectorSubtractPolynomials(parameters, w, cs2);

      final int r0Max =
          r.expand((polynomial) => polynomial).reduce((int a, int b) {
        final int x = lowBits(parameters, a);
        final int y = lowBits(parameters, b);

        return x.abs() > y.abs() ? x.abs() : y.abs();
      });

      final int zMax =
          z.expand((polynomial) => polynomial).reduce((int a, int b) => a.abs() > b.abs() ? a.abs() : b.abs());

      if (zMax >= parameters.gamma1() - parameters.beta() ||
          r0Max >= parameters.gamma2() - parameters.beta()) {
        z = null;
        h = null;
      } else {
        final List<List<int>> ct0 = vectorNttInverse(
            parameters, scalarVectorNtt(parameters, cHat, t0Hat));
        final List<List<int>> ct0Neg =
            scalarVectorMultiply(parameters, -1, ct0);

        final List<List<int>> wPrime = vectorAddPolynomials(
            parameters, vectorSubtractPolynomials(parameters, w, cs2), ct0);

        h = List.generate(ct0Neg.length, (int i) {
          return List.generate(ct0Neg[0].length, (int j) {
            return makeHint(parameters, ct0Neg[i][j], wPrime[i][j]);
          }, growable: false);
        }, growable: false);

        final int ct0Max =
            ct0.expand((row) => row).reduce((int a, int b) => a > b ? a : b);
        final int onesInH =
            h.expand((row) => row).reduce((int a, int b) => a + b);

        if (ct0Max >= parameters.gamma2() || onesInH > parameters.omega()) {
          z = null;
          h = null;
        }
      }

      k += parameters.l();
    }

    final List<List<int>> zModQSymmetric = List.generate(z!.length, (int i) {
      return List.generate(z![i].length, (int j) {
        return modQSymmetric(z![i][j], parameters.q());
      });
    });

    final Uint8List sigma = sigEncode(parameters, cTilde, zModQSymmetric, h!);

    return sigma;
  }

  bool _verify(Uint8List pk, Uint8List mPrime, Uint8List sigma) {
    return false;
  }
}
