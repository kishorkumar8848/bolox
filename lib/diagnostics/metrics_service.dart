import 'dart:io';

class MetricsService {
  int rtf = 0; // Real-Time Factor
  int lastLatencyMs = 0;
  int get ramUsageMB {
    try {
      return (ProcessInfo.currentRss / (1024 * 1024)).round();
    } catch (_) {
      return 0; // Fallback for some platforms
    }
  }
  
  void recordLatency(int latencyMs) {
    lastLatencyMs = latencyMs;
  }
}
