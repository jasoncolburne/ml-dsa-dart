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
  b2 &= 0x7f;

  final z = 65536 * b2 + 256 * b1 + b0;
  if (z < parameters.q()) {
    return z;
  }

  return null;
}

Uint8List bitsToBytes(Uint8List y) {
  final alpha = y.length;
  final Uint8List z = Uint8List((alpha + 7) ~/ 8);

  int j = 0;
  for (int i = 0; i < alpha; i += 8) {
    int mask = 0x01;

    for (int k = i; k < i + 8; k++) {
      int toCombine = 255;

      if (y[k] == 1) {
        toCombine = mask;
      } else {
        toCombine = 0;
      }

      z[j] |= toCombine;
      mask <<= 1;
    }

    j++;
  }

  return z;
}

Uint8List bytesToBits(Uint8List z) {
  final zLength = z.length;
  final Uint8List zPrime = Uint8List.fromList(z);
  final Uint8List y = Uint8List(8 * zLength);

  for (int i = 0; i < zLength; i++) {
    for (int j = 0; j < 8; j++) {
      y[8 * i + j] = zPrime[i] & 0x1;
      zPrime[i] ~/= 2;
    }
  }

  return y;
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
    y[i] = xPrime & 0x1;
    xPrime ~/= 2;
  }

  return y;
}

Uint8List integerToBytes(int x, int alpha) {
  final Uint8List y = Uint8List(alpha);

  int xPrime = x;
  for (int i = 0; i < alpha; i++) {
    y[i] = modQ(xPrime, 256);
    xPrime ~/= 256;
  }

  return y;
}

Uint8List pkEncode(ParameterSet parameters, Uint8List rho, List<Int32List> t) {
  final int k = parameters.k();
  final int width = (parameters.q() - 1).bitLength - parameters.d();
  final int rhoLength = rho.length;
  final int rangeLength = (width * 256) ~/ 8;
  final int b = (1 << width) - 1;
  final Uint8List pk = Uint8List(rhoLength + rangeLength * k);

  pk.setRange(0, rhoLength, rho);

  int offset = rhoLength;
  int limit = rhoLength;

  for (int i = 0; i < k; i++) {
    limit += rangeLength;
    pk.setRange(offset, limit, simpleBitPack(t[i], b));
    offset += rangeLength;
  }

  return pk;
}

(Uint8List, List<Int32List>) pkDecode(ParameterSet parameters, Uint8List pk) {
  final int k = parameters.k();
  final Uint8List rho = pk.sublist(0, 32);
  final Uint8List z = Uint8List.view(pk.buffer, 32);
  final int toShift = (parameters.q() - 1).bitLength - parameters.d();
  final int width = 32 * toShift;
  final int b = (1 << toShift) - 1;

  int offset = z.offsetInBytes;

  final List<Int32List> t = List.filled(k, Int32List(0), growable: false);

  for (int i = 0; i < k; i++) {
    Uint8List view = Uint8List.view(z.buffer, offset, width);
    t[i] = simpleBitUnpack(view, b);
    offset += width;
  }

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
  final int k = parameters.k();
  final int l = parameters.l();
  final int eta = parameters.eta();
  final int x = 1 << (parameters.d() - 1);
  final int y = x - 1;

  final int etaBlockLength = (eta + eta).bitLength * 32;
  final int xyBlockLength = (x + y).bitLength * 32;

  final int s1EncodedLength = s1.length * etaBlockLength;
  final int s2EncodedLength = s2.length * etaBlockLength;
  final int tEncodedLength = t.length * xyBlockLength;

  final int length = rho.length +
      kappa.length +
      tr.length +
      s1EncodedLength +
      s2EncodedLength +
      tEncodedLength;

  final Uint8List sk = Uint8List(length);

  int offset = 0;
  int limit = rho.length;
  sk.setRange(offset, limit, rho);

  offset += rho.length;
  limit += kappa.length;
  sk.setRange(offset, limit, kappa);

  offset += kappa.length;
  limit += tr.length;
  sk.setRange(offset, limit, tr);

  offset += tr.length;
  for (int i = 0; i < l; i++) {
    limit += etaBlockLength;
    sk.setRange(offset, limit, bitPack(s1[i], eta, eta));
    offset += etaBlockLength;
  }

  for (int i = 0; i < k; i++) {
    limit += etaBlockLength;
    sk.setRange(offset, limit, bitPack(s2[i], eta, eta));
    offset += etaBlockLength;
  }

  for (int i = 0; i < k; i++) {
    limit += xyBlockLength;
    sk.setRange(offset, limit, bitPack(t[i], y, x));
    offset += xyBlockLength;
  }

  return sk;
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

  final int eta = parameters.eta();
  final int d = parameters.d();
  final int k = parameters.k();
  final int l = parameters.l();
  final int width = 32 * (eta + eta).bitLength;
  final int wWidth = 32 * d;
  final int x = 1 << (d - 1);
  final int y = x - 1;

  int yOffset = 128;
  int zOffset = yOffset + l * width;
  int tOffset = zOffset + k * width;

  final List<Int32List> s1 = List.filled(l, Int32List(0), growable: false);
  final List<Int32List> s2 = List.filled(k, Int32List(0), growable: false);
  final List<Int32List> t = List.filled(k, Int32List(0), growable: false);

  for (int i = 0; i < k; i++) {
    if (i < l) {
      final Uint8List y = Uint8List.view(sk.buffer, yOffset, width);
      s1[i] = bitUnpack(y, eta, eta);
      yOffset += width;
    }

    final Uint8List w = Uint8List.view(sk.buffer, tOffset, wWidth);
    final Uint8List z = Uint8List.view(sk.buffer, zOffset, width);

    t[i] = bitUnpack(w, y, x);
    s2[i] = bitUnpack(z, eta, eta);

    tOffset += wWidth;
    zOffset += width;
  }

  return (rho, kappa, tr, s1, s2, t);
}

Uint8List sigEncode(
  ParameterSet parameters,
  Uint8List cTilde,
  List<Int32List> z,
  List<Uint8List> h,
) {
  final int l = parameters.l();
  final int gamma1 = parameters.gamma1();
  final int bitLength = (gamma1 + gamma1 - 1).bitLength;
  final int blockLength = bitLength * 32;
  final int length = cTilde.length +
      blockLength * parameters.l() +
      (parameters.omega() + parameters.k());
  final Uint8List sigma = Uint8List(length);
  sigma.setRange(0, cTilde.length, cTilde);

  int offset = cTilde.length;
  int limit = offset;

  for (int i = 0; i < l; i++) {
    limit += blockLength;
    sigma.setRange(offset, limit, bitPack(z[i], gamma1 - 1, gamma1));
    offset += blockLength;
  }

  sigma.setRange(offset, length, hintBitPack(parameters, h));

  return sigma;
}

(Uint8List, List<Int32List>, List<Uint8List>?) sigDecode(
  ParameterSet parameters,
  Uint8List sigma,
) {
  final int lambda = parameters.lambda();
  final int gamma1 = parameters.gamma1();
  int gamma1SubOne = gamma1 - 1;
  final int l = parameters.l();
  final int width = 32 * (1 + (gamma1 - 1).bitLength);
  final int lambdaByFour = lambda ~/ 4;

  final Uint8List cTilde = sigma.sublist(0, lambdaByFour);
  final Uint8List x =
      Uint8List.view(sigma.buffer, lambdaByFour, lambdaByFour + l * width);
  final Uint8List y = Uint8List.view(sigma.buffer, lambdaByFour + l * width);

  int offset = x.offsetInBytes;

  final List<Int32List> z = List.filled(l, Int32List(0), growable: false);

  for (int i = 0; i < l; i++) {
    Uint8List view = Uint8List.view(x.buffer, offset, width);

    z[i] = bitUnpack(
      view,
      gamma1SubOne,
      gamma1,
    );

    offset += width;
  }

  final List<Uint8List>? h = hintBitUnpack(parameters, y);

  return (cTilde, z, h);
}

Uint8List w1Encode(ParameterSet parameters, List<Int32List> w) {
  final int b = ((parameters.q() - 1) ~/ (2 * parameters.gamma2())) - 1;
  final int bitLength = b.bitLength;
  final int rangeLength = (256 * bitLength) ~/ 8;
  final Uint8List w1Tilde = Uint8List(bitLength * 32 * w.length);

  int offset = 0;
  int limit = 0;

  for (int i = 0; i < w.length; i++) {
    limit += rangeLength;
    w1Tilde.setRange(offset, limit, simpleBitPack(w[i], b));
    offset += rangeLength;
  }

  return w1Tilde;
}

Uint8List bitPack(Int32List w, int a, int b) {
  final int bitLength = (a + b).bitLength;
  final Uint8List z = Uint8List(bitLength * 256);

  int offset = 0;
  int limit = 0;

  for (int i = 0; i < 256; i++) {
    limit += bitLength;
    z.setRange(offset, limit, integerToBits(b - w[i], bitLength));
    offset += bitLength;
  }

  return bitsToBytes(z);
}

Int32List bitUnpack(Uint8List v, int a, int b) {
  final int c = (a + b).bitLength;
  final Uint8List z = bytesToBits(v);

  int offset = 0;

  final Int32List w = Int32List(256);

  for (int i = 0; i < 256; i++) {
    Uint8List view = Uint8List.view(z.buffer, offset, c);
    w[i] = b - bitsToInteger(view, c);
    offset += c;
  }

  return w;
}

Uint8List simpleBitPack(Int32List w, int b) {
  final int bitLength = b.bitLength;
  final Uint8List z = Uint8List(bitLength * 256); // (b.bitLength * 256) ~/ 8

  int offset = 0;
  int limit = 0;

  for (int i = 0; i < 256; i++) {
    limit += bitLength;
    z.setRange(offset, limit, integerToBits(w[i], bitLength));
    offset += bitLength;
  }

  return bitsToBytes(z);
}

Int32List simpleBitUnpack(Uint8List v, int b) {
  final int c = b.bitLength;
  final Uint8List z = bytesToBits(v);

  int offset = 0;

  final Int32List w = Int32List(256);
  for (int i = 0; i < 256; i++) {
    Uint8List view = Uint8List.view(z.buffer, offset, c);
    w[i] = bitsToInteger(view, c);
    offset += c;
  }

  return w;
}

Uint8List hintBitPack(ParameterSet parameters, List<Uint8List> h) {
  final int omega = parameters.omega();
  final int k = parameters.k();
  final Uint8List y = Uint8List(omega + k);
  int index = 0;

  for (int i = 0; i < k; i++) {
    for (int j = 0; j < 256; j++) {
      if (h[i][j] == 1) {
        y[index] = j;
        index += 1;
      }
    }

    y[omega + i] = index;
  }

  return y;
}

List<Uint8List>? hintBitUnpack(ParameterSet parameters, Uint8List y) {
  final int k = parameters.k();
  int index = 0;
  final int omega = parameters.omega();

  final List<Uint8List> h = List.filled(k, Uint8List(0), growable: false);

  for (int i = 0; i < k; i++) {
    h[i] = Uint8List(256);

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
  final int length =
      args.map((Uint8List arg) => arg.length).reduce((int a, int b) => a + b);
  final Uint8List result = Uint8List(length);

  int offset = 0;
  int limit = 0;

  for (final arg in args) {
    limit += arg.length;
    result.setRange(offset, limit, arg);
    offset += arg.length;
  }

  return result;
}

Uint8List concatenateBytesAndSHAKE256(int outputLength, List<Uint8List> args) {
  Uint8List input;

  if (args.length == 1) {
    input = args[0];
  } else {
    input = concatenateBytes(args);
  }

  final IncrementalSHAKE hasher = IncrementalSHAKE(256);
  hasher.absorb(input);
  final Uint8List result = hasher.squeeze(outputLength);
  hasher.destroy();
  return result;
}
