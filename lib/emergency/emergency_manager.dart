import 'dart:async';
import 'package:flutter/foundation.dart';

class EmergencyManager extends ChangeNotifier {
  bool isEmergencyActive = false;

  void triggerEmergency() {
    isEmergencyActive = true;
    notifyListeners();
    // In a real app, this would set a flag on the packetizer to send high-priority packets
    // and bypass normal adaptive bitrate checks for maximum robustness.
  }

  void receiveEmergencyAlert() {
    isEmergencyActive = true;
    notifyListeners();
    // Play loud alert, vibrate, show red screen
  }

  void clearEmergency() {
    isEmergencyActive = false;
    notifyListeners();
  }
}
