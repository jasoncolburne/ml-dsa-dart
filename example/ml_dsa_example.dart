import 'dart:convert';
import 'dart:typed_data';

import 'package:ml_dsa/ml_dsa.dart';

void main() {
  // Create an instance, using ML-DSA-65 for example.
  final dsa = MLDSA(MLDSA65Parameters());

  // Generate a key pair
  final (pk, sk) = dsa.keyGen();

  // Create some data to sign
  final msg = utf8.encode("Hello world! Sign me!");

  // This can be empty
  final ctx = Uint8List.fromList([0x99, 0x101, 0x109]);

  // Sign the message
  final sig = dsa.sign(sk, msg, ctx);

  // Verify the signature
  if (dsa.verify(pk, msg, sig, ctx)) {
    print('Signature verification succeeded!');
  } else {
    print('Signature verification failed!');
  }
}
