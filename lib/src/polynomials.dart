import 'dart:typed_data';

import 'conversion.dart';
import 'shake.dart';
import 'ml_dsa_base.dart';
import 'reduction.dart';

Int32List sampleInBall(ParameterSet parameters, Uint8List rho) {
  final int tau = parameters.tau();

  final Int32List c = Int32List(256);

  IncrementalSHAKE hasher = IncrementalSHAKE(256);
  hasher.absorb(rho);
  final Uint8List s = hasher.squeeze(8);

  final Uint8List h = bytesToBits(s);
  for (int i = 256 - tau; i < 256; i++) {
    Uint8List jSlice = hasher.squeeze(1);

    while (jSlice[0] > i) {
      jSlice = hasher.squeeze(1);
    }

    final int j = jSlice[0];
    c[i] = c[j];

    if (h[i + tau - 256] == 1) {
      c[j] = -1;
    } else {
      c[j] = 1;
    }
  }

  hasher.destroy();

  return c;
}

Int32List rejNttPoly(ParameterSet parameters, Uint8List rho) {
  final Int32List a = Int32List(256);

  IncrementalSHAKE hasher = IncrementalSHAKE(128);
  hasher.absorb(rho);

  int j = 0;
  while (j < 256) {
    final Uint8List s = hasher.squeeze(3);

    final coefficient = coeffFromThreeBytes(parameters, s[0], s[1], s[2]);
    if (coefficient == null) {
      continue;
    }

    a[j] = coefficient;
    j += 1;
  }

  hasher.destroy();

  return a;
}

Int32List rejBoundedPoly(ParameterSet parameters, Uint8List rho) {
  final Int32List a = Int32List(256);

  IncrementalSHAKE hasher = IncrementalSHAKE(256);
  hasher.absorb(rho);

  int j = 0;
  while (j < 256) {
    final Uint8List zArray = hasher.squeeze(1);

    final int z = zArray[0];
    final int? z0 = coeffFromHalfByte(parameters, modQ(z, 16));
    final int? z1 = coeffFromHalfByte(parameters, z ~/ 16);

    if (z0 != null) {
      a[j] = z0;
      j += 1;
    }

    if (z1 != null && j < 256) {
      a[j] = z1;
      j += 1;
    }
  }

  hasher.destroy();

  return a;
}

Int32List addPolynomials(ParameterSet parameters, Int32List a, Int32List b) {
  final int q = parameters.q();
  final Int32List c = Int32List(256);

  for (int i = 0; i < 256; i++) {
    c[i] = modQSymmetric(a[i] + b[i], q);
  }

  return c;
}

Int32List subtractPolynomials(
  ParameterSet parameters,
  Int32List a,
  Int32List b,
) {
  final int q = parameters.q();
  final Int32List c = Int32List(256);

  for (int i = 0; i < 256; i++) {
    c[i] = modQSymmetric(a[i] - b[i], q);
  }

  return c;
}

List<Int32List> vectorAddPolynomials(
  ParameterSet parameters,
  List<Int32List> a,
  List<Int32List> b,
) {
  final length = a.length;
  final List<Int32List> c = List.filled(length, Int32List(0), growable: false);

  for (int i = 0; i < length; i++) {
    c[i] = addPolynomials(parameters, a[i], b[i]);
  }

  return c;
}

List<Int32List> vectorSubtractPolynomials(
  ParameterSet parameters,
  List<Int32List> a,
  List<Int32List> b,
) {
  final length = a.length;
  final List<Int32List> c = List.filled(length, Int32List(0), growable: false);

  for (int i = 0; i < length; i++) {
    c[i] = subtractPolynomials(parameters, a[i], b[i]);
  }

  return c;
}

List<Int32List> scalarVectorMultiply(
  ParameterSet parameters,
  int c,
  List<Int32List> v,
) {
  final int q = parameters.q();
  final int length = v.length;
  final int subLength = v[0].length;

  final List<Int32List> u = List.filled(length, Int32List(0), growable: false);
  for (int i = 0; i < length; i++) {
    u[i] = Int32List(subLength);
    for (int j = 0; j < subLength; j++) {
      u[i][j] = modQSymmetric(c * v[i][j], q);
    }
  }

  return u;
}
