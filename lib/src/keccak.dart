// ignore_for_file: camel_case_types, constant_identifier_names

import 'dart:ffi' as ffi;

final class KeccakP1600_plain64_state extends ffi.Struct {
  @ffi.Array.multi([25])
  external ffi.Array<ffi.Uint64> A;
}

typedef KeccakP1600_state = KeccakP1600_plain64_state;

final class KeccakWidth1600_SpongeInstanceStruct extends ffi.Struct {
  external KeccakP1600_state state;

  @ffi.UnsignedInt()
  external int rate;

  @ffi.UnsignedInt()
  external int byteIOIndex;

  @ffi.Int()
  external int squeezing;
}

typedef KeccakWidth1600_SpongeInstance = KeccakWidth1600_SpongeInstanceStruct;
typedef BitSequence = ffi.Uint8;
typedef DartBitSequence = int;
typedef BitLength = ffi.Size;
typedef DartBitLength = int;

enum HashReturn {
  KECCAK_SUCCESS(0),
  KECCAK_FAIL(1),
  KECCAK_BAD_HASHLEN(2);

  final int value;
  const HashReturn(this.value);

  static HashReturn fromValue(int value) => switch (value) {
        0 => KECCAK_SUCCESS,
        1 => KECCAK_FAIL,
        2 => KECCAK_BAD_HASHLEN,
        _ => throw ArgumentError("Unknown value for HashReturn: $value"),
      };
}

final class Keccak_HashInstance extends ffi.Struct {
  external KeccakWidth1600_SpongeInstance sponge;

  @ffi.UnsignedInt()
  external int fixedOutputLength;

  @ffi.UnsignedChar()
  external int delimitedSuffix;
}

typedef NativeKeccak_HashInitialize = ffi.UnsignedInt Function(
    ffi.Pointer<Keccak_HashInstance> hashInstance,
    ffi.UnsignedInt rate,
    ffi.UnsignedInt capacity,
    ffi.UnsignedInt hashbitlen,
    ffi.UnsignedChar delimitedSuffix);
typedef DartKeccak_HashInitialize = int Function(
    ffi.Pointer<Keccak_HashInstance> hashInstance,
    int rate,
    int capacity,
    int hashbitlen,
    int delimitedSuffix);
typedef NativeKeccak_HashUpdate = ffi.UnsignedInt Function(
    ffi.Pointer<Keccak_HashInstance> hashInstance,
    ffi.Pointer<BitSequence> data,
    BitLength databitlen);
typedef DartKeccak_HashUpdate = int Function(
    ffi.Pointer<Keccak_HashInstance> hashInstance,
    ffi.Pointer<BitSequence> data,
    int databitlen);
typedef NativeKeccak_HashSqueeze = ffi.UnsignedInt Function(
    ffi.Pointer<Keccak_HashInstance> hashInstance,
    ffi.Pointer<BitSequence> data,
    BitLength databitlen);
typedef DartKeccak_HashSqueeze = int Function(
    ffi.Pointer<Keccak_HashInstance> hashInstance,
    ffi.Pointer<BitSequence> data,
    int databitlen);
typedef NativeSHA3_512 = ffi.Int Function(ffi.Pointer<ffi.Uint8> output,
    ffi.Pointer<ffi.Uint8> input, ffi.Size inputByteLen);
typedef DartSHA3_512 = int Function(ffi.Pointer<ffi.Uint8> output,
    ffi.Pointer<ffi.Uint8> input, int inputByteLen);
