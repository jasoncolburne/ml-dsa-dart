// TODO: confirm conformance

import 'dart:math';
import 'dart:typed_data';

Uint8List rbg(int len) {
  final drbg = Random.secure();
  final entropy = Uint8List(len);

  for (int i = 0; i < len; i++) {
    entropy[i] = drbg.nextInt(256);
  }

  return Uint8List.fromList(entropy);
}
