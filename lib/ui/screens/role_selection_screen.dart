import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../communication/communication_controller.dart';
import '../../core/constants/theme.dart';
import 'connection_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commController = Provider.of<CommunicationController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Are you sending or receiving?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(24),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                ),
                icon: const Icon(Icons.send, size: 32),
                label: const Text('I AM SENDER', style: TextStyle(fontSize: 20)),
                onPressed: () {
                  commController.setRole(Role.sender);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(24),
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.call_received, size: 32),
                label: const Text('I AM RECEIVER', style: TextStyle(fontSize: 20)),
                onPressed: () {
                  commController.setRole(Role.receiver);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
