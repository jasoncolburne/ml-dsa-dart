import 'dart:typed_data';

import 'conversion.dart';
import 'keccak.dart';
import 'ml_dsa_base.dart';
import 'polynomials.dart';

List<List<List<int>>> expandA(ParameterSet parameters, Uint8List rho) {
  final int rhoLength = rho.length;
  final List<int> rhoPrime = List<int>.generate(rhoLength, (int i) => rho[i]);
  rhoPrime.addAll([0, 0]);

  return List<List<List<int>>>.generate(parameters.k(), (int r) {
    return List<List<int>>.generate(parameters.l(), (int s) {
      rhoPrime[rhoLength] = integerToBytes(s, 1)[0];
      rhoPrime[rhoLength + 1] = integerToBytes(r, 1)[0];

      return rejNttPoly(parameters, Uint8List.fromList(rhoPrime));
    });
  });
}

(List<List<int>>, List<List<int>>) expandS(
    ParameterSet parameters, Uint8List rho) {
  final int rhoLength = rho.length;
  final List<int> rhoPrime = List<int>.generate(rhoLength, (int i) => rho[i]);
  rhoPrime.addAll([0, 0]);

  final List<List<int>> s1 = List<List<int>>.generate(parameters.l(), (int _) {
    return List<int>.empty();
  }, growable: false);
  final List<List<int>> s2 = List<List<int>>.generate(parameters.k(), (int _) {
    return List<int>.empty();
  }, growable: false);

  for (int r = 0; r < parameters.l(); r++) {
    final Uint8List bytes = integerToBytes(r, 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    s1[r] = rejBoundedPoly(parameters, Uint8List.fromList(rhoPrime));
  }

  for (int r = 0; r < parameters.l(); r++) {
    final Uint8List bytes = integerToBytes(r + parameters.l(), 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    s2[r] = rejBoundedPoly(parameters, Uint8List.fromList(rhoPrime));
  }

  return (s1, s2);
}

List<List<int>> expandMask(ParameterSet parameters, Uint8List rho, int mu) {
  final int rhoLength = rho.length;
  final List<int> rhoPrime = List<int>.generate(rhoLength, (int i) => rho[i]);
  rhoPrime.addAll([0, 0]);

  final int c = 1 + (parameters.gamma1() - 1).bitLength;

  return List<List<int>>.generate(parameters.l(), (int r) {
    final Uint8List bytes = integerToBytes(mu + r, 2);
    rhoPrime[rhoLength] = bytes[0];
    rhoPrime[rhoLength + 1] = bytes[1];
    
    final Keccak hasher = Keccak(KeccakAlgorithm.shake256);
    hasher.absorb(Uint8List.fromList(rhoPrime));
    final Uint8List v = hasher.squeeze(32 * c);
    return bitUnpack(v, parameters.gamma1() - 1, parameters.gamma1());
  });
}
