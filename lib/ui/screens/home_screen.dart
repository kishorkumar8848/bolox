import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../communication/communication_controller.dart';
import 'connection_screen.dart';
import 'settings_screen.dart';
import 'diagnostics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String transportMode = 'Bluetooth';

  late AnimationController _pttController;
  late Animation<double> _pttPulseAnimation;

  @override
  void initState() {
    super.initState();
    _pttController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pttPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pttController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pttController.dispose();
    super.dispose();
  }

  void _onPttDown(TapDownDetails details, CommunicationController commController) {
    commController.startPtt();
    _pttController.repeat(reverse: true);
  }

  void _onPttUp(TapUpDetails details, CommunicationController commController) {
    commController.stopPtt();
    _pttController.reset();
  }

  void _onPttCancel(CommunicationController commController) {
    commController.stopPtt();
    _pttController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final commController = Provider.of<CommunicationController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BoloX RADIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () async {
              await commController.disconnect();
              if (mounted) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                 );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(commController),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                  );
                },
                child: _buildDiagnosticInfo(commController),
              ),
              const Spacer(),
              _buildPttButton(commController),
              const SizedBox(height: 48),
              _buildBottomControls(commController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(CommunicationController commController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Connection:', style: Theme.of(context).textTheme.bodyLarge),
                Row(
                  children: [
                    Icon(
                      commController.isConnected ? Icons.check_circle : Icons.error,
                      color: commController.isConnected ? AppTheme.success : AppTheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      commController.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                      style: TextStyle(
                        color: commController.isConnected ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transport:', style: Theme.of(context).textTheme.bodyLarge),
                Text(transportMode, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Language:', style: Theme.of(context).textTheme.bodyLarge),
                DropdownButton<String>(
                  value: commController.currentLanguage,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      commController.setLanguage(newValue);
                    }
                  },
                  items: CommunicationController.sttLocales.keys.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticInfo(CommunicationController commController) {
    return AnimatedOpacity(
      opacity: commController.isTransmitting || commController.isReceiving ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Text(
            commController.isTransmitting ? 'TRANSMITTING...' : (commController.isReceiving ? 'RECEIVING...' : 'IDLE'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Semantic Transmission (Text)'),
          Text('Role: ${commController.role.name.toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _buildPttButton(CommunicationController commController) {
    return GestureDetector(
      onTapDown: commController.isDuplexMode ? null : (details) => _onPttDown(details, commController),
      onTapUp: commController.isDuplexMode ? null : (details) => _onPttUp(details, commController),
      onTapCancel: commController.isDuplexMode ? null : () => _onPttCancel(commController),
      onTap: commController.isDuplexMode ? () {
        if (commController.isTransmitting) {
          commController.stopPtt();
          _pttController.stop();
        } else {
          commController.startPtt();
          _pttController.repeat(reverse: true);
        }
      } : null,
      child: ScaleTransition(
        scale: _pttPulseAnimation,
        child: Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: commController.isTransmitting ? AppTheme.primary.withValues(alpha: 0.8) : AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: commController.isTransmitting ? AppTheme.primary.withValues(alpha: 0.5) : Colors.black26,
                blurRadius: 30,
                spreadRadius: 10,
              )
            ],
            border: Border.all(
              color: AppTheme.primary,
              width: 4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                size: 64,
                color: commController.isTransmitting ? AppTheme.background : AppTheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                commController.isDuplexMode 
                  ? (commController.isTransmitting ? 'IN CALL' : 'START CALL')
                  : 'HOLD TO TALK',
                style: TextStyle(
                  color: commController.isTransmitting ? AppTheme.background : AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(CommunicationController commController) {
    return Column(
      children: [
        if (commController.peerLocation != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peer Location:\n${commController.peerLocation}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Walkie-Talkie', style: TextStyle(color: AppTheme.textSecondary)),
            Switch(
              value: commController.isDuplexMode,
              onChanged: (val) => commController.toggleDuplexMode(),
              activeColor: AppTheme.primary,
            ),
            const Text('Phone Mode', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                  );
                },
                icon: const Icon(Icons.bluetooth),
                label: const Text('CONNECT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  commController.sendEmergencyAlert();
                },
                icon: const Icon(Icons.warning),
                label: const Text('EMERGENCY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            commController.sendLocation();
          },
          icon: const Icon(Icons.my_location),
          label: const Text('SHARE LOCATION OFFLINE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.background,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}
