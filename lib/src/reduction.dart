import 'dart:typed_data';

import 'ml_dsa_base.dart';

int modMultiply(int a, int b, int q) {
  return (a * b) % q;
}

int modQ(int n, int q) {
  return (n % q + q) % q;
}

int modQSymmetric(int n, int q) {
  int result = modQ(n, q);

  if (result > q ~/ 2) {
    result -= q;
  }

  return result;
}

List<Int32List> vectorModQSymmetric(List<Int32List> z, int q) {
  return List.generate(z.length, (int i) {
    return Int32List.fromList(List.generate(z[i].length, (int j) {
      return modQSymmetric(z[i][j], q);
    }, growable: false));
  }, growable: false);
}

(int, int) power2Round(ParameterSet parameters, int r) {
  final int rPlus = modQ(r, parameters.q());
  final int bound = 1 << parameters.d();
  final int r0 = modQSymmetric(rPlus, bound);

  return ((rPlus - r0) ~/ bound, r0);
}

(List<Int32List>, List<Int32List>) vectorPower2Round(
    ParameterSet parameters, List<Int32List> t) {
  final List<Int32List> t0 = List.generate(
    parameters.k(),
    (_) => Int32List(256),
    growable: false,
  );
  final List<Int32List> t1 = List.generate(
    parameters.k(),
    (_) => Int32List(256),
    growable: false,
  );

  for (int j = 0; j < parameters.k(); j++) {
    for (int i = 0; i < 256; i++) {
      final (int y, int x) = power2Round(parameters, t[j][i]);
      t1[j][i] = y;
      t0[j][i] = x;
    }
  }

  return (t1, t0);
}

(int, int) decompose(ParameterSet parameters, int r) {
  int rPlus = modQ(r, parameters.q());
  int r0 = modQSymmetric(rPlus, 2 * parameters.gamma2());
  int r1 = 0;

  if (rPlus - r0 == parameters.q() - 1) {
    r0 -= 1;
  } else {
    r1 = (rPlus - r0) ~/ (2 * parameters.gamma2());
  }

  return (r1, r0);
}

int highBits(ParameterSet parameters, int r) {
  final (int r1, _) = decompose(parameters, r);
  return r1;
}

List<Int32List> vectorHighBits(ParameterSet parameters, List<Int32List> v) {
  return List.generate(parameters.k(), (int j) {
    return Int32List.fromList(List.generate(256, (int i) {
      return highBits(parameters, v[j][i]);
    }, growable: false));
  }, growable: false);
}

int lowBits(ParameterSet parameters, int r) {
  final (_, int r0) = decompose(parameters, r);
  return r0;
}

int makeHint(ParameterSet parameters, int z, int r) {
  final int r1 = highBits(parameters, r);
  final int v1 = highBits(parameters, r + z);

  return (r1 != v1) ? 1 : 0;
}

List<Uint8List> vectorMakeHint(
    ParameterSet parameters, List<Int32List> ct0Neg, List<Int32List> wPrime) {
  return List.generate(ct0Neg.length, (int i) {
    return Uint8List.fromList(List.generate(ct0Neg[i].length, (int j) {
      return makeHint(parameters, ct0Neg[i][j], wPrime[i][j]);
    }, growable: false));
  }, growable: false);
}

int useHint(ParameterSet parameters, int h, int r) {
  final int m = (parameters.q() - 1) ~/ (2 * parameters.gamma2());
  final (int r1, int r0) = decompose(parameters, r);

  if (h == 1) {
    if (r0 > 0) {
      return modQ(r1 + 1, m);
    } else {
      return modQ(r1 - 1, m);
    }
  }

  return r1;
}

List<Int32List> vectorUseHint(
    ParameterSet parameters, List<Int32List> v, List<Uint8List> h) {
  return List.generate(parameters.k(), (int i) {
    return Int32List.fromList(List.generate(v[i].length, (int j) {
      return useHint(parameters, h[i][j], v[i][j]);
    }, growable: false));
  }, growable: false);
}

int onesInH(List<Uint8List> h) {
  return h.expand((row) => row).reduce((int a, int b) => a + b);
}

int vectorMaxAbsCoefficient(
  ParameterSet parameters,
  List<Int32List> v, {
  bool lowBitsOnly = false,
}) {
  return v.expand((row) => row).reduce((int a, int b) {
    int x, y;

    if (lowBitsOnly) {
      x = lowBits(parameters, a);
      y = lowBits(parameters, b);
    } else {
      x = a;
      y = b;
    }

    return x.abs() > y.abs() ? x.abs() : y.abs();
  });
}
