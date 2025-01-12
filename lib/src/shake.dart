import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform, Directory;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'keccak.dart';

class IncrementalSHAKE {
  final int bitLength;

  late ffi.Pointer<Keccak_HashInstance> _shake;

  late DartKeccak_HashInitialize _initializeFn;
  late DartKeccak_HashUpdate _updateFn;
  late DartKeccak_HashSqueeze _squeezeFn;

  IncrementalSHAKE(this.bitLength) {
    final String extension = Platform.isMacOS ? '.dylib' : '.so';

    _shake = calloc<Keccak_HashInstance>(ffi.sizeOf<Keccak_HashInstance>());

    final libraryPath =
        path.join(Directory.current.path, 'build', 'libkeccak$extension');
    final library = ffi.DynamicLibrary.open(libraryPath);

    _initializeFn = library.lookupFunction<NativeKeccak_HashInitialize,
        DartKeccak_HashInitialize>('Keccak_HashInitialize');
    _updateFn =
        library.lookupFunction<NativeKeccak_HashUpdate, DartKeccak_HashUpdate>(
            'Keccak_HashUpdate');
    _squeezeFn = library.lookupFunction<NativeKeccak_HashSqueeze,
        DartKeccak_HashSqueeze>('Keccak_HashSqueeze');

    reset();
  }

  void destroy() {
    calloc.free(_shake);
  }

  void absorb(Uint8List input) {
    final buffer = calloc<ffi.Uint8>(input.length);
    final typedList = buffer.asTypedList(input.length);
    typedList.setAll(0, input);

    try {
      final int result = _updateFn(_shake, buffer, input.length * 8);
      if (result != HashReturn.KECCAK_SUCCESS.value) {
        throw Exception('failure absorbing: $result');
      }
    } finally {
      calloc.free(buffer);
    }
  }

  Uint8List squeeze(int outputLength) {
    Uint8List output = Uint8List(outputLength);
    final buffer = calloc<ffi.Uint8>(outputLength);

    try {
      final int result = _squeezeFn(_shake, buffer, outputLength * 8);
      if (result != HashReturn.KECCAK_SUCCESS.value) {
        throw Exception('failure squeezing: $result');
      }

      final typedList = buffer.asTypedList(outputLength);
      output.setAll(0, typedList);
    } finally {
      calloc.free(buffer);
    }

    return output;
  }

  void reset() {
    switch (bitLength) {
      case 128:
        _initializeFn(_shake, 1344, 256, 0, 0x1F);
      case 256:
        _initializeFn(_shake, 1088, 512, 0, 0x1F);
      default:
        throw Exception('programmer error');
    }
  }
}
