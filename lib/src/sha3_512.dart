import 'dart:io';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'keccak.dart';

// ignore: camel_case_types
class SHA3_512 {
  late DartSHA3_512 _digestFn;

  SHA3_512() {
    final String extension = Platform.isMacOS ? '.dylib' : '.so';

    final libraryPath =
        path.join(Directory.current.path, 'build', 'libkeccak$extension');
    final library = ffi.DynamicLibrary.open(libraryPath);

    _digestFn =
        library.lookupFunction<NativeSHA3_512, DartSHA3_512>('SHA3_512');
  }

  Uint8List digest(Uint8List input) {
    Uint8List output = Uint8List(64);

    final ffi.Pointer<ffi.Uint8> inputBuffer = calloc<ffi.Uint8>(input.length);
    final ffi.Pointer<ffi.Uint8> outputBuffer = calloc<ffi.Uint8>(64);
    final Uint8List typedInputList = inputBuffer.asTypedList(input.length);
    typedInputList.setAll(0, input);

    try {
      final int result = _digestFn(outputBuffer, inputBuffer, input.length * 8);
      if (result != 0) {
        throw Exception('failure calling sha3-512: $result');
      }

      final Uint8List typedOutputList = outputBuffer.asTypedList(64);
      output.setAll(0, typedOutputList);
    } finally {
      calloc.free(inputBuffer);
      calloc.free(outputBuffer);
    }

    return output;
  }
}
