// TODO: confirm conformance

import 'dart:math';
import 'dart:typed_data';

Uint8List rbg(int len) {
  final drbg = Random.secure();
  final entropy = List.generate(len, (int _) => drbg.nextInt(256));
  return Uint8List.fromList(entropy);
}
