// Conditional imports for web downloads
import 'dart:typed_data';
import 'download_helper_stub.dart' // Stub implementation
    if (dart.library.html) 'download_helper.dart'; // Web implementation

void downloadFile(Uint8List bytes, String fileName) {
  downloadFileWeb(bytes, fileName);
}
