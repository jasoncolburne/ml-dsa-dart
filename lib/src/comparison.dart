import 'dart:typed_data';

bool constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;

  final len = a.length;
  final aWords = Uint32List.view(a.buffer, a.offsetInBytes, len ~/ 4);
  final bWords = Uint32List.view(b.buffer, b.offsetInBytes, len ~/ 4);

  int result = 0;
  for (int i = 0; i < aWords.length; i++) {
    result |= aWords[i] ^ bWords[i];
  }

  for (int i = len & ~3; i < len; i++) {
    result |= a[i] ^ b[i];
  }

  return result == 0;
}
