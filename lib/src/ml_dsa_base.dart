// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'comparison.dart';
import 'conversion.dart';
import 'entropy.dart';
import 'expansion.dart';
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

    final Uint8List rnd = rbg(seedLength);

    final Uint8List mPrime = concatenateBytes([
      integerToBytes(0, 1),
      integerToBytes(ctx.length, 1),
      ctx,
      message,
    ]);

    return _sign(sk, mPrime, rnd);
  }

  Uint8List signDeterministically(
      Uint8List sk, Uint8List message, Uint8List ctx) {
    if (ctx.length > 255) {
      throw Exception('ctx length > 255');
    }

    final Uint8List rnd = Uint8List(seedLength);

    final Uint8List mPrime = concatenateBytes([
      integerToBytes(0, 1),
      integerToBytes(ctx.length, 1),
      ctx,
      message,
    ]);

    return _sign(sk, mPrime, rnd);
  }

  bool verify(
    Uint8List pk,
    Uint8List message,
    Uint8List signature,
    Uint8List ctx,
  ) {
    if (ctx.length > 255) {
      throw Exception('ctx length > 255');
    }

    final Uint8List mPrime = concatenateBytes([
      integerToBytes(0, 1),
      integerToBytes(ctx.length, 1),
      ctx,
      message,
    ]);

    return _verify(pk, mPrime, signature);
  }

  (Uint8List, Uint8List) _keyGen(Uint8List rnd) {
    final Uint8List bytes = concatenateBytesAndSHAKE256(128, [
      rnd,
      integerToBytes(parameters.k(), 1),
      integerToBytes(parameters.l(), 1),
    ]);

    final Uint8List rho = bytes.sublist(0, 32);
    final Uint8List rhoPrime = bytes.sublist(32, 96);
    final Uint8List kappa = bytes.sublist(96);

    final List<List<Int32List>> AHat = expandA(parameters, rho);
    final (List<Int32List> s1, List<Int32List> s2) = expandS(
      parameters,
      rhoPrime,
    );
    final List<Int32List> s1Hat = vectorNtt(parameters, s1);
    final List<Int32List> product = matrixVectorNtt(parameters, AHat, s1Hat);
    final List<Int32List> t = vectorAddPolynomials(
      parameters,
      vectorNttInverse(parameters, product),
      s2,
    );
    final (List<Int32List> t1, List<Int32List> t0) = vectorPower2Round(
      parameters,
      t,
    );

    final Uint8List pk = pkEncode(parameters, rho, t1);

    final Uint8List tr = concatenateBytesAndSHAKE256(64, [pk]);
    final Uint8List sk = skEncode(parameters, rho, kappa, tr, s1, s2, t0);

    return (pk, sk);
  }

  Uint8List _sign(Uint8List sk, Uint8List mPrime, Uint8List rnd) {
    final (
      Uint8List rho,
      Uint8List kappa,
      Uint8List tr,
      List<Int32List> s1,
      List<Int32List> s2,
      List<Int32List> t0
    ) = skDecode(parameters, sk);

    final List<Int32List> s1Hat = vectorNtt(parameters, s1);
    final List<Int32List> s2Hat = vectorNtt(parameters, s2);
    final List<Int32List> t0Hat = vectorNtt(parameters, t0);
    final List<List<Int32List>> AHat = expandA(parameters, rho);

    final Uint8List mu = concatenateBytesAndSHAKE256(64, [tr, mPrime]);
    final Uint8List rhoPrimePrime = concatenateBytesAndSHAKE256(64, [
      kappa,
      rnd,
      mu,
    ]);

    int k = 0;
    List<Int32List>? z;
    List<Uint8List>? h;
    Uint8List cTilde = Uint8List(0);

    while (z == null && h == null) {
      final List<Int32List> y = expandMask(
        parameters,
        rhoPrimePrime,
        k,
      );

      final List<Int32List> yHat = vectorNtt(parameters, y);
      final List<Int32List> product = matrixVectorNtt(parameters, AHat, yHat);
      final List<Int32List> w = vectorNttInverse(parameters, product);
      final List<Int32List> w1 = vectorHighBits(parameters, w);

      cTilde = concatenateBytesAndSHAKE256(parameters.lambda() ~/ 4, [
        mu,
        w1Encode(parameters, w1),
      ]);

      final Int32List c = sampleInBall(parameters, cTilde);
      final Int32List cHat = ntt(parameters, c);

      final List<Int32List> cs1 = vectorNttInverse(
        parameters,
        scalarVectorNtt(parameters, cHat, s1Hat),
      );
      final List<Int32List> cs2 = vectorNttInverse(
        parameters,
        scalarVectorNtt(parameters, cHat, s2Hat),
      );

      z = vectorAddPolynomials(parameters, y, cs1);
      final List<Int32List> r = vectorSubtractPolynomials(parameters, w, cs2);

      final int r0Max = vectorMaxAbsCoefficient(
        parameters,
        r,
        lowBitsOnly: true,
      );
      final int zMax = vectorMaxAbsCoefficient(parameters, z);
      if (zMax >= parameters.gamma1() - parameters.beta() ||
          r0Max >= parameters.gamma2() - parameters.beta()) {
        z = null;
        h = null;
      } else {
        final List<Int32List> ct0 = vectorNttInverse(
          parameters,
          scalarVectorNtt(parameters, cHat, t0Hat),
        );
        final List<Int32List> ct0Neg = scalarVectorMultiply(
          parameters,
          -1,
          ct0,
        );
        final List<Int32List> wPrime = vectorAddPolynomials(
          parameters,
          vectorSubtractPolynomials(parameters, w, cs2),
          ct0,
        );

        h = vectorMakeHint(parameters, ct0Neg, wPrime);
        final int ct0Max = vectorMaxAbsCoefficient(parameters, ct0);
        if (ct0Max >= parameters.gamma2() || onesInH(h) > parameters.omega()) {
          z = null;
          h = null;
        }
      }

      k += parameters.l();
    }

    final List<Int32List> zModQSymmetric =
        vectorModQSymmetric(z!, parameters.q());
    final Uint8List sigma = sigEncode(parameters, cTilde, zModQSymmetric, h!);

    return sigma;
  }

  bool _verify(Uint8List pk, Uint8List mPrime, Uint8List sigma) {
    final (Uint8List rho, List<Int32List> t1) = pkDecode(parameters, pk);
    final (Uint8List cTilde, List<Int32List> z, List<Uint8List>? h) =
        sigDecode(parameters, sigma);

    if (h == null) {
      return false;
    }

    final List<List<Int32List>> AHat = expandA(parameters, rho);

    final Uint8List tr = concatenateBytesAndSHAKE256(64, [pk]);
    final Uint8List mu = concatenateBytesAndSHAKE256(64, [tr, mPrime]);

    final Int32List c = sampleInBall(parameters, cTilde);
    final Int32List cHat = ntt(parameters, c);

    final List<Int32List> ct = scalarVectorNtt(
      parameters,
      cHat,
      vectorNtt(
        parameters,
        scalarVectorMultiply(parameters, 1 << parameters.d(), t1),
      ),
    );
    final List<Int32List> Az = matrixVectorNtt(
      parameters,
      AHat,
      vectorNtt(parameters, z),
    );
    final List<Int32List> Azct = subtractVectorNtt(parameters, Az, ct);

    final List<Int32List> wApproxPrime = vectorNttInverse(parameters, Azct);
    final List<Int32List> w1Prime = vectorUseHint(parameters, wApproxPrime, h);

    final Uint8List cTildePrime = concatenateBytesAndSHAKE256(
      parameters.lambda() ~/ 4,
      [mu, w1Encode(parameters, w1Prime)],
    );
    final int zMax = vectorMaxAbsCoefficient(parameters, z);

    return zMax < (parameters.gamma1() - parameters.beta()) &&
        constantTimeEquals(cTilde, cTildePrime);
  }
}
