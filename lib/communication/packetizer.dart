import 'dart:typed_data';
import 'packet.dart';
import 'crc.dart';

class Packetizer {
  /// Wraps a RadioPacket with a CRC and returns the final byte array to transmit.
  static Uint8List encode(RadioPacket packet) {
    final rawBytes = packet.toBytes();
    final crc = Crc16.calculate(rawBytes);
    
    final builder = BytesBuilder();
    builder.add(rawBytes);
    builder.addByte((crc >> 8) & 0xFF);
    builder.addByte(crc & 0xFF);
    return builder.toBytes();
  }

  /// Parses raw bytes back into a RadioPacket.
  /// Validates the CRC. Returns null if invalid or corrupted.
  static RadioPacket? decode(Uint8List bytes) {
    if (bytes.length < 18) return null; // 16 header + 2 crc min

    final packetLength = bytes.length - 2;
    final packetBytes = bytes.sublist(0, packetLength);
    final expectedCrc = (bytes[packetLength] << 8) | bytes[packetLength + 1];
    
    final actualCrc = Crc16.calculate(packetBytes);
    if (expectedCrc != actualCrc) {
      print('CRC Mismatch: Expected $expectedCrc, got $actualCrc');
      return null;
    }

    return RadioPacket.fromBytes(packetBytes);
  }
}
