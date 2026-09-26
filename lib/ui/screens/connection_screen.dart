import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../communication/communication_controller.dart';
import '../../core/constants/theme.dart';
import 'home_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final List<Map<String, String>> _discoveredEndpoints = [];
  StreamSubscription? _discoveredSub;
  StreamSubscription? _lostSub;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRoleLogic();
    });
  }

  void _initRoleLogic() {
    final commController = Provider.of<CommunicationController>(context, listen: false);

    // Set up the incoming connection callback
    commController.onIncomingConnection = (endpointId, endpointName) {
      _showIncomingConnectionDialog(commController, endpointId, endpointName);
    };

    if (commController.role == Role.receiver) {
      commController.startAdvertising('BoloX_Receiver');
    } else if (commController.role == Role.sender) {
      commController.startDiscovery('BoloX_Sender');
      _discoveredSub = commController.transport.onEndpointDiscovered.listen((endpoint) {
        setState(() {
          if (!_discoveredEndpoints.any((e) => e['endpointId'] == endpoint['endpointId'])) {
            _discoveredEndpoints.add(endpoint);
          }
        });
      });
      _lostSub = commController.transport.onEndpointLost.listen((id) {
        setState(() {
          _discoveredEndpoints.removeWhere((e) => e['endpointId'] == id);
        });
      });
    }
  }

  void _showIncomingConnectionDialog(CommunicationController commController, String endpointId, String endpointName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Incoming Connection'),
          content: Text('$endpointName is trying to contact you.'),
          actions: [
            TextButton(
              onPressed: () {
                commController.rejectConnection(endpointId);
                Navigator.of(context).pop();
              },
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await commController.acceptConnection(endpointId);
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _discoveredSub?.cancel();
    _lostSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commController = Provider.of<CommunicationController>(context);

    if (commController.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(commController.role == Role.sender ? 'Discovering Devices' : 'Waiting for Sender')),
      body: commController.role == Role.receiver
          ? _buildReceiverView()
          : _buildSenderView(commController),
    );
  }

  Widget _buildReceiverView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Advertising as BoloX_Receiver...', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text('Waiting for a Sender to connect...'),
        ],
      ),
    );
  }

  Widget _buildSenderView(CommunicationController commController) {
    if (_discoveredEndpoints.isEmpty) {
      return const Center(child: Text('Scanning for receivers...'));
    }

    return ListView.builder(
      itemCount: _discoveredEndpoints.length,
      itemBuilder: (context, index) {
        final device = _discoveredEndpoints[index];
        return ListTile(
          leading: const Icon(Icons.wifi_tethering),
          title: Text(device['endpointName'] ?? 'Unknown'),
          subtitle: Text(device['endpointId'] ?? ''),
          trailing: _isConnecting
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.background,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isConnecting = true;
                    });
                    await commController.requestConnection(device['endpointId']!, 'BoloX_Sender');
                    // We wait for the connection status to change which handles navigation
                  },
                  child: const Text('Connect'),
                ),
        );
      },
    );
  }
}
