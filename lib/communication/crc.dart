import 'dart:typed_data';

class Crc16 {
  /// Simple CRC-16-CCITT implementation
  static int calculate(Uint8List bytes) {
    int crc = 0xFFFF;
    for (int i = 0; i < bytes.length; ++i) {
      crc ^= bytes[i] << 8;
      for (int j = 0; j < 8; ++j) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
      }
    }
    return crc & 0xFFFF;
  }
}
