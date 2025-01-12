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
  final int outerLength = z.length;
  final int innerLength = z[0].length;

  final List<Int32List> v =
      List.filled(outerLength, Int32List(0), growable: false);

  for (int i = 0; i < outerLength; i++) {
    v[i] = Int32List(innerLength);
    for (int j = 0; j < innerLength; j++) {
      v[i][j] = modQSymmetric(z[i][j], q);
    }
  }

  return v;
}

(int, int) power2Round(ParameterSet parameters, int r) {
  final int rPlus = modQ(r, parameters.q());
  final int bound = 1 << parameters.d();
  final int r0 = modQSymmetric(rPlus, bound);

  return ((rPlus - r0) ~/ bound, r0);
}

(List<Int32List>, List<Int32List>) vectorPower2Round(
    ParameterSet parameters, List<Int32List> t) {
  final int k = parameters.k();

  final List<Int32List> t0 = List.filled(k, Int32List(0), growable: false);
  final List<Int32List> t1 = List.filled(k, Int32List(0), growable: false);

  for (int j = 0; j < parameters.k(); j++) {
    t0[j] = Int32List(256);
    t1[j] = Int32List(256);

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
  final int k = parameters.k();

  final List<Int32List> u = List.filled(k, Int32List(0));

  for (int j = 0; j < k; j++) {
    u[j] = Int32List(256);
    for (int i = 0; i < 256; i++) {
      u[j][i] = highBits(parameters, v[j][i]);
    }
  }

  return u;
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
  ParameterSet parameters,
  List<Int32List> ct0Neg,
  List<Int32List> wPrime,
) {
  final outerLength = ct0Neg.length;
  final innerLength = ct0Neg[0].length;

  final List<Uint8List> h = List.filled(outerLength, Uint8List(0));

  for (int i = 0; i < outerLength; i++) {
    h[i] = Uint8List(innerLength);
    for (int j = 0; j < innerLength; j++) {
      h[i][j] = makeHint(parameters, ct0Neg[i][j], wPrime[i][j]);
    }
  }

  return h;
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
  ParameterSet parameters,
  List<Int32List> v,
  List<Uint8List> h,
) {
  final int k = parameters.k();
  final int innerLength = v[0].length;

  final List<Int32List> u = List.filled(k, Int32List(0));

  for (int i = 0; i < k; i++) {
    u[i] = Int32List(innerLength);
    for (int j = 0; j < innerLength; j++) {
      u[i][j] = useHint(parameters, h[i][j], v[i][j]);
    }
  }

  return u;
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
