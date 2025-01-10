import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class IncrementalSHAKE {
  final SHAKEDigest _shake;

  IncrementalSHAKE(bool isShake256)
      : _shake = isShake256 ? SHAKEDigest(256) : SHAKEDigest(128);

  void absorb(Uint8List input) {
    _shake.update(input, 0, input.length);
  }

  Uint8List squeeze(int outputLength) {
    Uint8List output = Uint8List(outputLength);

    // Squeeze the output into the buffer
    _shake.doOutput(output, 0, outputLength);

    return output;
  }

  void reset() {
    _shake.reset();
  }
}
