import 'dart:typed_data';

import 'ml_dsa_base.dart';
import 'reduction.dart';
import 'zetas.dart';

Int32List ntt(ParameterSet parameters, Int32List w) {
  final Int32List wHat = Int32List.fromList(w);

  int m = 0;
  final int q = parameters.q();

  for (int len = 128; len >= 1; len = len ~/ 2) {
    for (int start = 0; start < 256; start += 2 * len) {
      m += 1;
      final int z = zetas[m];

      for (int j = start; j < start + len; j++) {
        final int t = modMultiply(z, wHat[j + len], q);
        wHat[j + len] = modQ(wHat[j] - t, q);
        wHat[j] = modQ(wHat[j] + t, q);
      }
    }
  }

  return wHat;
}

Int32List nttInverse(ParameterSet parameters, Int32List wHat) {
  final Int32List w = Int32List.fromList(wHat);

  int m = 256;
  int len = 1;
  final int q = parameters.q();

  while (len < 256) {
    int start = 0;
    while (start < 256) {
      m -= 1;
      final int z = -zetas[m];
      for (int j = start; j < start + len; j++) {
        final t = w[j];
        w[j] = modQ(t + w[j + len], q);
        w[j + len] = modQ(t - w[j + len], q);
        w[j + len] = modMultiply(z, w[j + len], q);
      }
      start += 2 * len;
    }
    len = 2 * len;
  }

  final int f = 8347681;
  // modMultiply(f, 256, q) == 1

  for (int j = 0; j < 256; j++) {
    w[j] = modQSymmetric(modMultiply(f, w[j], q), q);
  }

  return w;
}

Int32List addNtt(ParameterSet parameters, Int32List aHat, Int32List bHat) {
  return Int32List.fromList(
    List.generate(
      256,
      (int i) => modQ(aHat[i] + bHat[i], parameters.q()),
      growable: false,
    ),
  );
}

Int32List subtractNtt(ParameterSet parameters, aHat, Int32List bHat) {
  return Int32List.fromList(
    List.generate(
      256,
      (int i) => modQ(aHat[i] - bHat[i], parameters.q()),
      growable: false,
    ),
  );
}

Int32List multiplyNtt(ParameterSet parameters, aHat, Int32List bHat) {
  return Int32List.fromList(List.generate(
    256,
    (int i) => modMultiply(aHat[i], bHat[i], parameters.q()),
    growable: false,
  ));
}

List<Int32List> vectorNtt(ParameterSet parameters, List<Int32List> vHat) {
  return List.generate(
    vHat.length,
    (int i) => ntt(parameters, vHat[i]),
    growable: false,
  );
}

List<Int32List> vectorNttInverse(
  ParameterSet parameters,
  List<Int32List> vHat,
) {
  return List.generate(
    vHat.length,
    (int i) => nttInverse(parameters, vHat[i]),
    growable: false,
  );
}

List<Int32List> subtractVectorNtt(
  ParameterSet parameters,
  List<Int32List> vHat,
  List<Int32List> wHat,
) {
  return List.generate(
    vHat.length,
    (int i) => subtractNtt(parameters, vHat[i], wHat[i]),
    growable: false,
  );
}

List<Int32List> scalarVectorNtt(
  ParameterSet parameters,
  Int32List cHat,
  List<Int32List> vHat,
) {
  return List.generate(
    vHat.length,
    (int i) => multiplyNtt(parameters, cHat, vHat[i]),
    growable: false,
  );
}

List<Int32List> matrixVectorNtt(
  ParameterSet parameters,
  // ignore: non_constant_identifier_names
  List<List<Int32List>> MHat,
  List<Int32List> vHat,
) {
  final List<Int32List> wHat = List.generate(
    parameters.k(),
    (_) => Int32List(256),
    growable: false,
  );

  for (int i = 0; i < parameters.k(); i++) {
    for (int j = 0; j < parameters.l(); j++) {
      wHat[i] = addNtt(
        parameters,
        wHat[i],
        multiplyNtt(parameters, MHat[i][j], vHat[j]),
      );
    }
  }

  return wHat;
}
