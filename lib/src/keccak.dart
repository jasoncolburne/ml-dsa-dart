import 'dart:typed_data';

class Utility {
  static int rotateLeft(int value, int shift, int mask) {
    return ((value << shift) & mask) | (value >> (64 - shift));
  }
}

enum KeccakAlgorithm {
  shake128,
  shake256,
}

class Keccak {
  Keccak(KeccakAlgorithm algorithm) {
    switch (algorithm) {
      case KeccakAlgorithm.shake128:
        // _r = 1344;
        // _c = 256;
        _blockSize = 168;
      case KeccakAlgorithm.shake256:
        // _r = 1088;
        // _c = 512;
        _blockSize = 136;
    }
  }

  static const List<int> RC = [
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808A,
    0x8000000080008000,
    0x000000000000808B,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008A,
    0x0000000000000088,
    0x8000000080008009,
    0x800000008000808B,
    0x8000000080018001,
    0x8000808000808009,
    0x800080800080808B,
    0x8000808000018081,
    0x800080800001808A,
    0x800080800001808B,
    0x800080800001809A,
    0x800080800001809B,
    0x80008080000180AA,
    0x80008080000180AB,
    0x80008080000180BA,
    0x80008080000180BB,
    0x80008080000180CA
  ];

  static const List<List<int>> R = [
    [0, 1, 62, 28, 27],
    [36, 44, 6, 55, 20],
    [3, 10, 43, 25, 39],
    [41, 45, 15, 21, 8],
    [18, 2, 61, 56, 14]
  ];

  final List<List<int>> _a = List.generate(5, (_) => List.filled(5, 0));
  // late int _r;
  // late int _c;
  // final int _d = 0x1f;
  final int _mask = (1 << 64) - 1;
  late int _blockSize;

  void keccakRound(int rc) {
    List<int> c = List.filled(5, 0);
    List<List<int>> b = List.generate(5, (_) => List.filled(5, 0));
    List<int> d = List.filled(5, 0);

    // θ step
    for (int x = 0; x < 5; x++) {
      c[x] = _a[x].reduce((a, b) => a ^ b);
    }

    for (int x = 0; x < 5; x++) {
      d[x] = c[(x - 1) % 5] ^ Utility.rotateLeft(c[(x + 1) % 5], 1, _mask);
    }

    for (int x = 0; x < 5; x++) {
      for (int y = 0; y < 5; y++) {
        _a[x][y] ^= d[x];
      }
    }

    // ρ and π steps
    for (int x = 0; x < 5; x++) {
      for (int y = 0; y < 5; y++) {
        b[y][(2 * x + 3 * y) % 5] =
            Utility.rotateLeft(_a[x][y], R[x][y], _mask);
      }
    }

    // χ step
    for (int x = 0; x < 5; x++) {
      for (int y = 0; y < 5; y++) {
        _a[x][y] = b[x][y] ^ (~b[(x + 1) % 5][y] & b[(x + 2) % 5][y]);
      }
    }

    // Ι step
    _a[0][0] ^= rc;
  }

  void absorb(Uint8List input) {
    int wordCount = input.length ~/ 8; // Each word is 8 bytes (64 bits)

    // Absorb the input into the state
    for (int i = 0; i < wordCount; i++) {
      int x = i % 5;
      int y = i ~/ 5;
      if (y < 5) {
        _a[x][y] ^= input.buffer.asUint64List()[i]; // XOR into state
      }
    }

    // Perform the Keccak round after absorbing
    keccakF1600(Uint64List(_blockSize)); // Absorb a block of zeros if needed
  }

  Uint8List squeeze(int outputLength) {
    Uint8List z = Uint8List(outputLength); // Output buffer
    int offset = 0;

    while (outputLength > 0) {
      int length = (_blockSize < outputLength) ? _blockSize : outputLength;
      Uint64List toPack = Uint64List(25);
      int index = 0;

      for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 5; x++) {
          toPack[index++] = _a[x][y];
        }
      }

      // Convert to bytes and store in z
      for (int i = offset; i < offset + length && i < z.length; i++) {
        z[i] = toPack[i - offset] & _mask;
      }

      outputLength -= length;
      offset += length;

      if (outputLength > 0) {
        keccakF1600(Uint64List(_blockSize)); // Absorb a block of zeros
      }
    }

    return z;
  }

  void keccakF1600(Uint64List block) {
    int wordCount = block.length;

    // Absorb the input block into the state array
    bool done = false;
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 5; x++) {
        if (y * 5 + x == wordCount) {
          done = true;
          break;
        }
        _a[x][y] ^= block[x + (5 * y)];
      }
      if (done) break;
    }

    // Perform the Keccak rounds
    for (int round = 0; round < 24; round++) {
      keccakRound(RC[round]);
    }
  }
}
