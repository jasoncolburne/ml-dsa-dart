import 'dart:typed_data';

import 'conversion.dart';
import 'shake.dart';
import 'ml_dsa_base.dart';
import 'polynomials.dart';

List<List<Int32List>> expandA(ParameterSet parameters, Uint8List rho) {
  final int k = parameters.k();
  final int l = parameters.l();
  final int rhoLength = rho.length;
  final Uint8List rhoPrime = Uint8List(rhoLength + 2);

  rhoPrime.setRange(0, rhoLength, rho);

  final List<List<Int32List>> A = List.filled(k, []);
  for (int r = 0; r < k; r++) {
    A[r] = List.filled(l, Int32List(0), growable: false);
    for (int s = 0; s < l; s++) {
      rhoPrime[rhoLength] = integerToBytes(s, 1)[0];
      rhoPrime[rhoLength + 1] = integerToBytes(r, 1)[0];
      A[r][s] = rejNttPoly(parameters, rhoPrime);
    }
  }

  return A;
}

(List<Int32List>, List<Int32List>) expandS(
  ParameterSet parameters,
  Uint8List rho,
) {
  final int k = parameters.k();
  final int l = parameters.l();
  final int rhoLength = rho.length;
  final Uint8List rhoPrime = Uint8List(rhoLength + 2);

  final List<Int32List> s1 = List.filled(l, Int32List(0), growable: false);
  final List<Int32List> s2 = List.filled(k, Int32List(0), growable: false);

  rhoPrime.setRange(0, rhoLength, rho);

  for (int r = 0; r < l; r++) {
    final Uint8List bytes = integerToBytes(r, 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    s1[r] = rejBoundedPoly(parameters, rhoPrime);
  }

  for (int r = 0; r < k; r++) {
    final Uint8List bytes = integerToBytes(r + l, 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    s2[r] = rejBoundedPoly(parameters, rhoPrime);
  }

  return (s1, s2);
}

List<Int32List> expandMask(ParameterSet parameters, Uint8List rho, int mu) {
  final int l = parameters.l();
  final int rhoLength = rho.length;
  final Uint8List rhoPrime = Uint8List(rho.length + 2);

  final int c = 1 + (parameters.gamma1() - 1).bitLength;
  final int blockSize = 32 * c;
  final int y = parameters.gamma1();
  final int x = y - 1;

  rhoPrime.setRange(0, rhoLength, rho);
  IncrementalSHAKE hasher = IncrementalSHAKE(256);
  final List<Int32List> u = List.filled(l, Int32List(0), growable: false);

  for (int r = 0; r < l; r++) {
    rhoPrime.setRange(rhoLength, rhoLength + 2, integerToBytes(mu + r, 2));
    hasher.absorb(rhoPrime);
    final Uint8List v = hasher.squeeze(blockSize);
    u[r] = bitUnpack(v, x, y);
    hasher.reset();
  }

  hasher.destroy();

  return u;
}
