import 'dart:typed_data';

import 'conversion.dart';
import 'keccak.dart';
import 'ml_dsa_base.dart';
import 'reduction.dart';

List<int> sampleInBall(ParameterSet parameters, Uint8List rho) {
  final List<int> c = List<int>.generate(256, (int _) => 0);

  final Keccak hasher = Keccak(KeccakAlgorithm.shake256);
  hasher.absorb(rho);
  final Uint8List s = hasher.squeeze(8);

  final List<int> h = bytesToBits(s);
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

List<int> rejNttPoly(ParameterSet parameters, Uint8List rho) {
  final List<int> a = List<int>.filled(256, 0, growable: false);

  final Keccak hasher = Keccak(KeccakAlgorithm.shake128);
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

List<int> rejBoundedPoly(ParameterSet parameters, Uint8List rho) {
  final List<int> a = List<int>.filled(256, 0, growable: false);

  final Keccak hasher = Keccak(KeccakAlgorithm.shake256);
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

List<int> addPolynomials(ParameterSet parameters, List<int> a, List<int> b) {
  return List.generate(256, (int i) {
    return modQSymmetric(a[i] + b[i], parameters.q());
  }, growable: false);
}

List<int> subtractPolynomials(
    ParameterSet parameters, List<int> a, List<int> b) {
  return List.generate(256, (int i) {
    return modQSymmetric(a[i] - b[i], parameters.q());
  }, growable: false);
}

List<List<int>> vectorAddPolynomials(
    ParameterSet parameters, List<List<int>> a, List<List<int>> b) {
  return List<List<int>>.generate(a.length, (int i) {
    return addPolynomials(parameters, a[i], b[i]);
  }, growable: false);
}

List<List<int>> vectorSubtractPolynomials(
    ParameterSet parameters, List<List<int>> a, List<List<int>> b) {
  return List<List<int>>.generate(a.length, (int i) {
    return subtractPolynomials(parameters, a[i], b[i]);
  }, growable: false);
}

List<List<int>> scalarVectorMultiply(
    ParameterSet parameters, int c, List<List<int>> v) {
  return List<List<int>>.generate(v.length, (int i) {
    return List<int>.generate(v[i].length, (int j) {
      return modQSymmetric(c * v[i][j], parameters.q());
    });
  });
}
