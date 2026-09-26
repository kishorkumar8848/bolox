import 'dart:typed_data';

class RadioPacket {
  static const int headerByte1 = 0xB0;
  static const int headerByte2 = 0x10;

  final int sourceId;
  final int destId;
  final int sessionId;
  final int sequenceNumber;
  final int frameId;
  final int codecMode;
  final int bitrateMode;
  final int timestamp;
  final Uint8List payload;

  RadioPacket({
    required this.sourceId,
    required this.destId,
    required this.sessionId,
    required this.sequenceNumber,
    required this.frameId,
    required this.codecMode,
    required this.bitrateMode,
    required this.timestamp,
    required this.payload,
  });

  /// 16 bytes overhead + payload + 2 bytes CRC (added by packetizer)
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.addByte(headerByte1);
    builder.addByte(headerByte2);
    
    // Convert all fields to 16-bit (2 bytes) except codec/bitrate mode (1 byte)
    _add16(builder, sourceId);
    _add16(builder, destId);
    _add16(builder, sessionId);
    _add16(builder, sequenceNumber);
    _add16(builder, frameId);
    
    builder.addByte(codecMode);
    builder.addByte(bitrateMode);
    
    _add64(builder, timestamp);
    
    _add16(builder, payload.length);
    builder.add(payload);
    
    return builder.toBytes();
  }

  static void _add16(BytesBuilder builder, int value) {
    builder.addByte((value >> 8) & 0xFF);
    builder.addByte(value & 0xFF);
  }

  static void _add64(BytesBuilder builder, int value) {
    for (int i = 7; i >= 0; i--) {
      builder.addByte((value >> (i * 8)) & 0xFF);
    }
  }

  static int _read16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static int _read64(Uint8List bytes, int offset) {
    int value = 0;
    for (int i = 0; i < 8; i++) {
      value = (value << 8) | bytes[offset + i];
    }
    return value;
  }

  static RadioPacket? fromBytes(Uint8List bytes) {
    if (bytes.length < 24) return null; // Increased min size for timestamp
    if (bytes[0] != headerByte1 || bytes[1] != headerByte2) return null;

    final sourceId = _read16(bytes, 2);
    final destId = _read16(bytes, 4);
    final sessionId = _read16(bytes, 6);
    final sequenceNumber = _read16(bytes, 8);
    final frameId = _read16(bytes, 10);
    final codecMode = bytes[12];
    final bitrateMode = bytes[13];
    final timestamp = _read64(bytes, 14);
    final payloadLength = _read16(bytes, 22);

    if (bytes.length < 24 + payloadLength) return null;

    final payload = bytes.sublist(24, 24 + payloadLength);

    return RadioPacket(
      sourceId: sourceId,
      destId: destId,
      sessionId: sessionId,
      sequenceNumber: sequenceNumber,
      frameId: frameId,
      codecMode: codecMode,
      bitrateMode: bitrateMode,
      timestamp: timestamp,
      payload: payload,
    );
  }
}
