// Stub for non-web platforms
import 'dart:typed_data';

void downloadFileWeb(Uint8List bytes, String fileName) {
  throw UnsupportedError('Web downloads not supported on this platform');
}
