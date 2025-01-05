import 'ml_dsa_base.dart';

int modMultiply(int a, int b, int q) {
  return (a * b) % q;
}

int modQSymmetric(int n, int q) {
  int result = modQ(n, q);

  if (result > (q / 2).floor()) {
    result -= q;
  }

  return result;
}

int modQ(int n, int q) {
  return (n % q + q) % q;
}

(int, int) power2Round(ParameterSet parameters, int r) {
  final int rPlus = modQ(r, parameters.q());
  final int bound = 1 << parameters.d();
  final int r0 = modQSymmetric(rPlus, bound);

  return ((rPlus - r0) ~/ bound, r0);
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

int lowBits(ParameterSet parameters, int r) {
  final (_, int r0) = decompose(parameters, r);
  return r0;
}

int makeHint(ParameterSet parameters, int z, int r) {
  final int r1 = highBits(parameters, r);
  final int v1 = highBits(parameters, r + z);

  return (r1 != v1) ? 1 : 0;
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
