import 'package:flutter/foundation.dart';

class Logger {
  static void log(String event, {int? sequenceNumber, String? packetType, String? bitrate, String? latency, String? codecMode, String? language}) {
    final timestamp = DateTime.now().toIso8601String();
    
    String msg = '[$timestamp] $event';
    if (sequenceNumber != null) msg += ' SEQ $sequenceNumber';
    if (packetType != null) msg += ' TYPE $packetType';
    if (bitrate != null) msg += ' BITRATE $bitrate';
    if (latency != null) msg += ' LATENCY $latency';
    if (codecMode != null) msg += ' CODEC $codecMode';
    if (language != null) msg += ' LANG $language';
    
    if (kDebugMode) {
      print(msg);
    }
  }
}
