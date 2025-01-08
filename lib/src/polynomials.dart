import 'dart:typed_data';

import 'conversion.dart';
import 'shake.dart';
import 'ml_dsa_base.dart';
import 'reduction.dart';

Int32List sampleInBall(ParameterSet parameters, Uint8List rho) {
  final Int32List c = Int32List(256);

  IncrementalSHAKE hasher = IncrementalSHAKE(true);
  hasher.absorb(rho);
  final Uint8List s = hasher.squeeze(8);

  final Uint8List h = bytesToBits(s);
  for (int i = 256 - parameters.tau(); i < 256; i++) {
    Uint8List jSlice = hasher.squeeze(1);

    while (jSlice[0] > i) {
      jSlice = hasher.squeeze(1);
    }

    final int j = jSlice[0];
    c[i] = c[j];

    if (h[i + parameters.tau() - 256] == 1) {
      c[j] = -1;
    } else {
      c[j] = 1;
    }
  }

  return c;
}

Int32List rejNttPoly(ParameterSet parameters, Uint8List rho) {
  final Int32List a = Int32List(256);

  IncrementalSHAKE hasher = IncrementalSHAKE(false);
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

  return a;
}

Int32List rejBoundedPoly(ParameterSet parameters, Uint8List rho) {
  final Int32List a = Int32List(256);

  IncrementalSHAKE hasher = IncrementalSHAKE(true);
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

  return a;
}

Int32List addPolynomials(ParameterSet parameters, Int32List a, Int32List b) {
  return Int32List.fromList(List.generate(256, (int i) {
    return modQSymmetric(a[i] + b[i], parameters.q());
  }, growable: false));
}

Int32List subtractPolynomials(
    ParameterSet parameters, Int32List a, Int32List b) {
  return Int32List.fromList(List.generate(256, (int i) {
    return modQSymmetric(a[i] - b[i], parameters.q());
  }, growable: false));
}

List<Int32List> vectorAddPolynomials(
    ParameterSet parameters, List<Int32List> a, List<Int32List> b) {
  return List.generate(a.length, (int i) {
    return addPolynomials(parameters, a[i], b[i]);
  }, growable: false);
}

List<Int32List> vectorSubtractPolynomials(
    ParameterSet parameters, List<Int32List> a, List<Int32List> b) {
  return List.generate(a.length, (int i) {
    return subtractPolynomials(parameters, a[i], b[i]);
  }, growable: false);
}

List<Int32List> scalarVectorMultiply(
    ParameterSet parameters, int c, List<Int32List> v) {
  return List.generate(v.length, (int i) {
    return Int32List.fromList(List.generate(v[i].length, (int j) {
      return modQSymmetric(c * v[i][j], parameters.q());
    }));
  });
}
