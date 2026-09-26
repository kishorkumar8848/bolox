import '../diagnostics/metrics_service.dart';

class AdaptiveBitrateController {
  final MetricsService metricsService = MetricsService();

  int _currentBitrateMode = 3; // Start at 3 kbps (GOOD channel)
  int get currentBitrateMode => _currentBitrateMode;

  double _packetLossRate = 0.0;
  
  void recordPacketLoss() {
    // Simple EWMA for packet loss
    _packetLossRate = _packetLossRate * 0.9 + 0.1;
    _evaluateChannel();
  }

  void recordTransmissionLatency(Duration latency) {
    // Latency heuristic for demo
  }

  void simulatePacketLoss(double lossPercentage) {
     _packetLossRate = lossPercentage / 100.0;
     _evaluateChannel();
  }

  void _evaluateChannel() {
    if (_packetLossRate > 0.15) {
      _currentBitrateMode = 1; // POOR
    } else if (_packetLossRate > 0.05) {
      _currentBitrateMode = 2; // MEDIUM
    } else {
      _currentBitrateMode = 3; // GOOD
    }
  }
}
