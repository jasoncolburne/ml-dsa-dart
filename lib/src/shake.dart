import 'dart:typed_data';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import 'keccak.dart';

class IncrementalSHAKE {
  final int bitLength;

  late ffi.Pointer<Keccak_HashInstance> _shake;

  IncrementalSHAKE(this.bitLength) {
    _shake = calloc<Keccak_HashInstance>(ffi.sizeOf<Keccak_HashInstance>());
    reset();
  }

  void destroy() {
    calloc.free(_shake);
  }

  void absorb(Uint8List input) {
    final ffi.Pointer<ffi.Uint8> buffer = calloc<ffi.Uint8>(input.length);
    final Uint8List typedList = buffer.asTypedList(input.length);
    typedList.setAll(0, input);

    try {
      final int result = KeccakLibrary().keccakHashUpdate(_shake, buffer, input.length * 8);
      if (result != HashReturn.KECCAK_SUCCESS.value) {
        throw Exception('failure absorbing: $result');
      }
    } finally {
      calloc.free(buffer);
    }
  }

  Uint8List squeeze(int outputLength) {
    final Uint8List output = Uint8List(outputLength);
    final ffi.Pointer<ffi.Uint8> buffer = calloc<ffi.Uint8>(outputLength);

    try {
      final int result = KeccakLibrary().keccakHashSqueeze(_shake, buffer, outputLength * 8);
      if (result != HashReturn.KECCAK_SUCCESS.value) {
        throw Exception('failure squeezing: $result');
      }

      final Uint8List typedList = buffer.asTypedList(outputLength);
      output.setAll(0, typedList);
    } finally {
      calloc.free(buffer);
    }

    return output;
  }

  void reset() {
    switch (bitLength) {
      case 128:
        KeccakLibrary().keccakHashInitialize(_shake, 1344, 256, 0, 0x1F);
      case 256:
        KeccakLibrary().keccakHashInitialize(_shake, 1088, 512, 0, 0x1F);
      default:
        throw Exception('programmer error');
    }
  }
}
