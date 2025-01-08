import 'dart:typed_data';

import 'ml_dsa_base.dart';
import 'reduction.dart';
import 'shake.dart';

int? coeffFromHalfByte(ParameterSet parameters, int b) {
  if (parameters.eta() == 2 && b < 15) {
    final int result = 2 - modQ(b, 5);
    return result;
  }

  if (parameters.eta() == 4 && b < 9) {
    final int result = 4 - b;
    return result;
  }

  return null;
}

int? coeffFromThreeBytes(ParameterSet parameters, int b0, int b1, int b2) {
  int b2Prime = b2;
  if (b2Prime > 127) {
    b2Prime -= 128;
  }

  final z = 65536 * b2Prime + 256 * b1 + b0;
  if (z < parameters.q()) {
    return z;
  }

  return null;
}

Uint8List bitsToBytes(Uint8List y) {
  final alpha = y.length;
  final Uint8List z = Uint8List((alpha + 7) ~/ 8);

  for (int i = 0; i < alpha; i++) {
    if (y[i] == 1) {
      z[i ~/ 8] += 1 << modQ(i, 8);
    }
  }

  return z;
}

Uint8List bytesToBits(Uint8List z) {
  final zLength = z.length;
  final Uint8List zPrime = Uint8List.fromList(z);
  final Uint8List y = Uint8List(8 * zLength);

  for (int i = 0; i < zLength; i++) {
    for (int j = 0; j < 8; j++) {
      y[8 * i + j] = modQ(zPrime[i], 2);
      zPrime[i] ~/= 2;
    }
  }

  return Uint8List.fromList(y);
}

int bitsToInteger(Uint8List y, int alpha) {
  int x = 0;

  for (int i = 1; i <= alpha; i++) {
    x <<= 1;
    if (y[alpha - i] == 1) {
      x += 1;
    }
  }

  return x;
}

Uint8List integerToBits(int x, int alpha) {
  final Uint8List y = Uint8List(alpha);
  int xPrime = x;

  for (int i = 0; i < alpha; i++) {
    y[i] = modQ(xPrime, 2);
    xPrime = xPrime ~/ 2;
  }

  return y;
}

Uint8List integerToBytes(int x, int alpha) {
  final Int32List y = Int32List(alpha);

  int xPrime = x;
  for (int i = 0; i < alpha; i++) {
    y[i] = modQ(xPrime, 256);
    xPrime = xPrime ~/ 256;
  }

  return Uint8List.fromList(y);
}

Uint8List pkEncode(ParameterSet parameters, Uint8List rho, List<Int32List> t) {
  final int width = (parameters.q() - 1).bitLength - parameters.d();
  final List<int> pk = List.from(rho);

  for (int i = 0; i < parameters.k(); i++) {
    pk.addAll(simpleBitPack(t[i], (1 << width) - 1));
  }

  return Uint8List.fromList(pk);
}

(Uint8List, List<Int32List>) pkDecode(ParameterSet parameters, Uint8List pk) {
  final Uint8List rho = pk.sublist(0, 32);
  final Uint8List z = pk.sublist(32);
  final int toShift = (parameters.q() - 1).bitLength - parameters.d();
  final int width = 32 * toShift;

  final List<Int32List> t = List.generate(parameters.k(), (int i) {
    final offset = i * width;
    final limit = offset + width;
    return simpleBitUnpack(z.sublist(offset, limit), (1 << toShift) - 1);
  }, growable: false);

  return (rho, t);
}

Uint8List skEncode(
  ParameterSet parameters,
  Uint8List rho,
  Uint8List kappa,
  Uint8List tr,
  List<Int32List> s1,
  List<Int32List> s2,
  List<Int32List> t,
) {
  final List<int> sk = List.from(rho);
  sk.addAll(kappa);
  sk.addAll(tr);

  final int eta = parameters.eta();

  for (int i = 0; i < parameters.l(); i++) {
    sk.addAll(bitPack(s1[i], eta, eta));
  }

  for (int i = 0; i < parameters.k(); i++) {
    sk.addAll(bitPack(s2[i], eta, eta));
  }

  final int x = 1 << (parameters.d() - 1);
  final int y = x - 1;

  for (int i = 0; i < parameters.k(); i++) {
    sk.addAll(bitPack(t[i], y, x));
  }

  return Uint8List.fromList(sk);
}

// this function uses named returns, brace yourself
(
  Uint8List,
  Uint8List,
  Uint8List,
  List<Int32List>,
  List<Int32List>,
  List<Int32List>
) skDecode(ParameterSet parameters, Uint8List sk) {
  final Uint8List rho = sk.sublist(0, 32);
  final Uint8List kappa = sk.sublist(32, 64);
  final Uint8List tr = sk.sublist(64, 128);

  int baseOffset = 128;

  final int eta = parameters.eta();
  final int width = 32 * (2 * eta).bitLength;

  final List<Int32List> s1 = List.generate(parameters.l(), (int i) {
    final int offset = baseOffset + width * i;
    final int limit = offset + width;
    final Uint8List y = sk.sublist(offset, limit);
    return bitUnpack(y, eta, eta);
  }, growable: false);

  baseOffset += width * parameters.l();

  final List<Int32List> s2 = List.generate(parameters.k(), (int i) {
    final offset = baseOffset + width * i;
    final int limit = offset + width;
    final Uint8List z = sk.sublist(offset, limit);
    return bitUnpack(z, eta, eta);
  }, growable: false);

  baseOffset += width * parameters.k();
  final int wWidth = 32 * parameters.d();
  final int x = 1 << (parameters.d() - 1);
  final int y = x - 1;

  final List<Int32List> t = List.generate(parameters.k(), (int i) {
    final int offset = baseOffset + wWidth * i;
    final int limit = offset + wWidth;
    final Uint8List w = sk.sublist(offset, limit);
    return bitUnpack(w, y, x);
  }, growable: false);

  return (rho, kappa, tr, s1, s2, t);
}

Uint8List sigEncode(ParameterSet parameters, Uint8List cTilde,
    List<Int32List> z, List<Int32List> h) {
  final List<int> sigma = List.from(cTilde);

  final int gamma1 = parameters.gamma1();
  for (int i = 0; i < parameters.l(); i++) {
    sigma.addAll(bitPack(z[i], gamma1 - 1, gamma1));
  }

  final Uint8List hints = hintBitPack(parameters, h);
  sigma.addAll(hints);

  return Uint8List.fromList(sigma);
}

(Uint8List, List<Int32List>, List<Int32List>?) sigDecode(
    ParameterSet parameters, Uint8List sigma) {
  final int width = 32 * (1 + (parameters.gamma1() - 1).bitLength);

  final Uint8List cTilde = sigma.sublist(0, parameters.lambda() ~/ 4);
  final Uint8List x = sigma.sublist(parameters.lambda() ~/ 4,
      parameters.lambda() ~/ 4 + parameters.l() * width);
  final Uint8List y =
      sigma.sublist(parameters.lambda() ~/ 4 + parameters.l() * width);

  final z = List.generate(parameters.l(), (int i) {
    final int offset = i * width;
    final int limit = offset + width;
    return bitUnpack(
        x.sublist(offset, limit), parameters.gamma1() - 1, parameters.gamma1());
  }, growable: false);

  final List<Int32List>? h = hintBitUnpack(parameters, y);

  return (cTilde, z, h);
}

Uint8List w1Encode(ParameterSet parameters, List<Int32List> w) {
  final Uint8List w1Tilde = Uint8List(0);
  for (int i = 0; i < w.length; i++) {
    final int b = ((parameters.q() - 1) ~/ (2 * parameters.gamma2())) - 1;
    w1Tilde.addAll(simpleBitPack(w[i], b));
  }

  return w1Tilde;
}

Uint8List bitPack(Int32List w, int a, int b) {
  final List<int> z = List.empty(growable: true);

  for (int i = 0; i < 256; i++) {
    z.addAll(integerToBits(b - w[i], (a + b).bitLength));
  }

  return bitsToBytes(Uint8List.fromList(z));
}

Int32List bitUnpack(Uint8List v, int a, int b) {
  final int c = (a + b).bitLength;
  final Uint8List z = bytesToBits(v);

  final Int32List w = Int32List.fromList(List.generate(256, (int i) {
    final int offset = i * c;
    final int limit = offset + c;
    return b - bitsToInteger(z.sublist(offset, limit), c);
  }, growable: false));

  return w;
}

Uint8List simpleBitPack(Int32List w, int b) {
  final Uint8List z = Uint8List((b.bitLength * 256) ~/ 8);
  for (int i = 0; i < 256; i++) {
    z.setAll(0, integerToBits(w[i], b.bitLength));
  }

  return bitsToBytes(z);
}

Int32List simpleBitUnpack(Uint8List v, int b) {
  final int c = b.bitLength;
  final Uint8List z = bytesToBits(v);

  final Int32List w = Int32List.fromList(List.generate(256, (int i) {
    final offset = i * c;
    final limit = offset + c;
    return bitsToInteger(z.sublist(offset, limit), c);
  }, growable: false));

  return w;
}

Uint8List hintBitPack(ParameterSet parameters, List<Int32List> h) {
  final Int32List y = Int32List(
      parameters.omega() + parameters.k());
  int index = 0;

  for (int i = 0; i < parameters.k(); i++) {
    for (int j = 0; j < 256; j++) {
      if (h[i][j] == 1) {
        y[index] = j;
        index += 1;
      }
    }

    y[parameters.omega() + i] = index;
  }

  return Uint8List.fromList(y);
}

List<Int32List>? hintBitUnpack(ParameterSet parameters, Uint8List y) {
  int index = 0;
  final int omega = parameters.omega();

  final List<Int32List> h = List.generate(parameters.k(), (int i) {
    return Int32List(256);
  }, growable: false);

  for (int i = 0; i < parameters.k(); i++) {
    final int yOmegaI = y[omega + i];

    if (yOmegaI < index || yOmegaI > omega) {
      return null;
    }

    final int first = index;
    while (index < yOmegaI) {
      if (index > first) {
        if (y[index - 1] >= y[index]) {
          return null;
        }
      }

      h[i][y[index]] = 1;
      index += 1;
    }
  }

  for (int i = index; i < omega; i++) {
    if (y[i] != 0) {
      return null;
    }
  }

  return h;
}

Uint8List concatenateBytes(List<Uint8List> args) {
  final List<int> result = List.empty(growable: true);

  for (final arg in args) {
    result.addAll(arg);
  }

  return Uint8List.fromList(result);
}

Uint8List concatenateBytesAndSHAKE256(int outputLength, List<Uint8List> args) {
  Uint8List input;

  if (args.length == 1) {
    input = args[0];
  } else {
    input = concatenateBytes(args);
  }

  final IncrementalSHAKE hasher = IncrementalSHAKE(true);
  hasher.absorb(input);
  return hasher.squeeze(outputLength);
}
