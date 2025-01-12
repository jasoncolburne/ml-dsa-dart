// TODO: confirm conformance

import 'dart:math';
import 'dart:typed_data';

import 'sha3_512.dart';

Uint8List rbg(int len) {
  final rnd = Random.secure();
  final entropy =
      Uint8List.fromList(List.generate(32, (_) => rnd.nextInt(256)));

  final HashDRBG drbg =
      HashDRBG(entropy, Uint8List.fromList([73, 0xde, 0xad, 0xbe, 0xef]));
  return drbg.generate(len * 8);
}

class HashDRBG {
  late SHA3_512 _sha3;

  late int _seedLength;
  late int _reseedCounter;

  late Uint8List _v;
  late Uint8List _c;

  HashDRBG(Uint8List entropy, Uint8List personalizationString) {
    _seedLength = 888;

    final Uint8List seedMaterial =
        Uint8List(entropy.length + personalizationString.length);
    seedMaterial.setRange(0, entropy.length, entropy);
    seedMaterial.setAll(entropy.length, personalizationString);

    _sha3 = SHA3_512();
    _reseed(seedMaterial);
  }

  void _reseed(Uint8List seedMaterial) {
    _v = _derive(seedMaterial, _seedLength);
    final Uint8List vPrime = Uint8List.fromList([1, ..._v]);
    _c = _derive(vPrime, _seedLength);
    _reseedCounter = 1;
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    return BigInt.parse(
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);
  }

  Uint8List _bigIntToBytes(BigInt number, int length) {
    String hexString = number.toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList(List<int>.generate(length,
        (i) => int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  Uint8List _derive(Uint8List input, int numberOfBits) {
    final int numberOfBytes = (numberOfBits + 7) ~/ 8;
    final Uint8List output = Uint8List(numberOfBytes);

    Uint8List temp = Uint8List.fromList(input);

    int offset = 0;
    while (offset < numberOfBytes) {
      temp = Uint8List.fromList([1, ...temp]);

      final Uint8List dig = _sha3.digest(temp);
      final int digLength = dig.length;

      final int bytesToWrite = digLength < numberOfBytes - offset
          ? digLength
          : numberOfBytes - offset;
      output.setRange(offset, offset + bytesToWrite, dig);

      offset += bytesToWrite;
    }

    return output;
  }

  Uint8List generate(int numberOfBits) {
    if (_reseedCounter > (1 << 48)) {
      throw Exception('reseed required');
    }

    final int numberOfBytes = (numberOfBits + 7) ~/ 8;
    final Uint8List output = Uint8List(numberOfBytes);

    int offset = 0;
    while (offset < numberOfBytes) {
      _v = _sha3.digest(_v);
      final int digLength = _v.length;

      final int bytesToWrite = digLength < numberOfBytes - offset
          ? digLength
          : numberOfBytes - offset;
      output.setRange(offset, offset + bytesToWrite, _v);
      offset += bytesToWrite;
    }

    BigInt v = _bytesToBigInt(_v);
    BigInt c = _bytesToBigInt(_c);

    BigInt sum = v + c + BigInt.from(_reseedCounter);
    _v = _bigIntToBytes(sum, _seedLength ~/ 8);

    _reseedCounter += 1;

    return output;
  }

  void reseed(Uint8List entropy) {
    final Uint8List seedMaterial = Uint8List(1 + _v.length + entropy.length);
    seedMaterial[0] = 0x01;
    seedMaterial.setRange(1, 1 + _v.length, _v);
    seedMaterial.setAll(1 + _v.length, entropy);
    _reseed(seedMaterial);
  }
}
