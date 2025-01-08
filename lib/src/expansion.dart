import 'dart:typed_data';

import 'conversion.dart';
import 'shake.dart';
import 'ml_dsa_base.dart';
import 'polynomials.dart';

List<List<Int32List>> expandA(ParameterSet parameters, Uint8List rho) {
  final int rhoLength = rho.length;
  final Uint8List rhoPrime = Uint8List(rhoLength + 2);
  rhoPrime.setAll(0, rho);

  return List.generate(parameters.k(), (int r) {
    return List.generate(parameters.l(), (int s) {
      rhoPrime[rhoLength] = integerToBytes(s, 1)[0];
      rhoPrime[rhoLength + 1] = integerToBytes(r, 1)[0];

      return rejNttPoly(parameters, Uint8List.fromList(rhoPrime));
    });
  });
}

(List<Int32List>, List<Int32List>) expandS(
    ParameterSet parameters, Uint8List rho) {
  final int rhoLength = rho.length;
  final Uint8List rhoPrime = Uint8List(rhoLength + 2);
  rhoPrime.setAll(0, rho);

  final List<Int32List> s1 = List.filled(parameters.l(), 
     Int32List(0)
  , growable: false);
  final List<Int32List> s2 = List.filled(parameters.k(),
    Int32List(0)
  , growable: false);

  for (int r = 0; r < parameters.l(); r++) {
    final Uint8List bytes = integerToBytes(r, 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    s1[r] = rejBoundedPoly(parameters, Uint8List.fromList(rhoPrime));
  }

  for (int r = 0; r < parameters.k(); r++) {
    final Uint8List bytes = integerToBytes(r + parameters.l(), 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    s2[r] = rejBoundedPoly(parameters, Uint8List.fromList(rhoPrime));
  }

  return (s1, s2);
}

List<Int32List> expandMask(ParameterSet parameters, Uint8List rho, int mu) {
  final int rhoLength = rho.length;
  final Int32List rhoPrime = Int32List.fromList(rho);
  rhoPrime.addAll([0, 0]);

  final int c = 1 + (parameters.gamma1() - 1).bitLength;

  return List.generate(parameters.l(), (int r) {
    final Uint8List bytes = integerToBytes(mu + r, 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];

    IncrementalSHAKE hasher = IncrementalSHAKE(true);
    hasher.absorb(Uint8List.fromList(rhoPrime));
    final Uint8List v = hasher.squeeze(32 * c);
    return bitUnpack(v, parameters.gamma1() - 1, parameters.gamma1());
  });
}
