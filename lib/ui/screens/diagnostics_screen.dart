import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../communication/communication_controller.dart';
import '../../core/constants/theme.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<CommunicationController>(context);
    final metrics = comm.bitrateController.metricsService; // Accessing metrics
    
    return Scaffold(
      appBar: AppBar(title: const Text('Live Benchmarking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EVALUATION METRICS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 24),
            
            _buildMetricCard('Efficiency: Memory Footprint', '${metrics.ramUsageMB} MB RAM', Icons.memory),
            const SizedBox(height: 16),
            
            _buildMetricCard('Latency: End-to-End', '${metrics.lastLatencyMs} ms', Icons.speed),
            const SizedBox(height: 16),
            
            _buildMetricCard('Current Protocol', comm.isDuplexMode ? 'Full-Duplex (Live Stream)' : 'Walkie-Talkie (PTT)', Icons.settings_input_antenna),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      color: AppTheme.surface,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 32),
        title: Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
        subtitle: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
    );
  }
}
