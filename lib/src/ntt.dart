import 'ml_dsa_base.dart';
import 'reduction.dart';
import 'zetas.dart';

List<int> ntt(ParameterSet parameters, List<int> w) {
  final List<int> wHat = List.generate(256, (int i) => w[i], growable: false);

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

List<int> nttInverse(ParameterSet parameters, List<int> wHat) {
  final List<int> w = List.generate(256, (int i) => wHat[i], growable: false);

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

List<int> addNtt(ParameterSet parameters, List<int> aHat, List<int> bHat) {
  return List.generate(256, (int i) => modQ(aHat[i] + bHat[i], parameters.q()));
}

List<int> subtractNtt(ParameterSet parameters, aHat, List<int> bHat) {
  return List.generate(256, (int i) => modQ(aHat[i] - bHat[i], parameters.q()));
}

List<int> multiplyNtt(ParameterSet parameters, aHat, List<int> bHat) {
  return List.generate(
    256,
    (int i) => modMultiply(aHat[i], bHat[i], parameters.q()),
  );
}

List<List<int>> vectorNtt(ParameterSet parameters, List<List<int>> vHat) {
  return List.generate(vHat.length, (int i) => ntt(parameters, vHat[i]));
}

List<List<int>> vectorNttInverse(
    ParameterSet parameters, List<List<int>> vHat) {
  return List.generate(vHat.length, (int i) => nttInverse(parameters, vHat[i]));
}

List<List<int>> subtractVectorNtt(
    ParameterSet parameters, List<List<int>> vHat, List<List<int>> wHat) {
  return List.generate(
    vHat.length,
    (int i) => subtractNtt(parameters, vHat[i], wHat[i]),
  );
}

List<List<int>> scalarVectorNtt(
    ParameterSet parameters, List<int> cHat, List<List<int>> vHat) {
  return List.generate(
    vHat.length,
    (int i) => multiplyNtt(parameters, cHat, vHat[i]),
  );
}

List<List<int>> matrixVectorNtt(
  ParameterSet parameters,
  // ignore: non_constant_identifier_names
  List<List<List<int>>> MHat,
  List<List<int>> vHat,
) {
  final List<List<int>> wHat = List.generate(
    parameters.k(),
    (int _) {
      return List.generate(256, (int _) => 0, growable: false);
    },
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
