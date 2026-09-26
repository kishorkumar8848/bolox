import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../communication/communication_controller.dart';
import 'connection_screen.dart';
import 'offline_setup_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Bottom Background Image
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.4,
            child: Image.asset(
              'assets/images/bg_landscape.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.15),
                
                // Animated Ripple Radio Icon
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripples
                      ...List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            final delay = index * 0.3;
                            var value = _rippleController.value - delay;
                            if (value < 0) value += 1.0;
                            
                            return Opacity(
                              opacity: (1.0 - value).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 1.0 + (value * 2.5),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primary.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      
                      // Central Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ]
                        ),
                        child: const Icon(
                          Icons.radio,
                          size: 60,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Texts
                Text(
                  'iTANTRA',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 2,
                    fontSize: 42,
                    color: const Color(0xFF0F172A), // Dark navy
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'BoloX Neural Radio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Offline Multilingual Communication',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                const Spacer(),
                
                // Enter Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () => _showRoleSelectionDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('ENTER APP', style: TextStyle(letterSpacing: 1.5)),
                  ),
                ),
                
                // Offline Setup Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OfflineSetupScreen()),
                      );
                    },
                    icon: const Icon(Icons.download_for_offline),
                    label: const Text('OFFLINE SETUP (REQUIRED FIRST)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Select Your Role', style: TextStyle(color: AppTheme.primary)),
          content: const Text('Are you sending or receiving audio?', style: TextStyle(color: AppTheme.textPrimary)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _proceedWithRole(context, Role.receiver);
              },
              child: const Text('Receiver', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _proceedWithRole(context, Role.sender);
              },
              child: const Text('Sender'),
            ),
          ],
        );
      }
    );
  }

  void _proceedWithRole(BuildContext context, Role role) async {
    final commController = Provider.of<CommunicationController>(context, listen: false);
    commController.setRole(role);
    
    // Request permissions and initialize Bluetooth/Nearby
    await commController.transport.initialize();
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConnectionScreen()),
      );
    }
  }
}
