import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme.dart';
import 'ui/screens/landing_screen.dart';
import 'communication/nearby_transport.dart';
import 'communication/communication_controller.dart';
import 'speech/audio_manager.dart';
import 'speech/offline_stt.dart';
import 'speech/offline_tts.dart';
import 'adaptive/bitrate_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final transport = NearbyTransport();
  final audioManager = AudioManager();
  final stt = NativeSTT();
  final tts = NativeTTS();
  final bitrateController = AdaptiveBitrateController();

  final commController = CommunicationController(
    transport: transport,
    audioManager: audioManager,
    stt: stt,
    tts: tts,
    bitrateController: bitrateController,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CommunicationController>.value(value: commController),
      ],
      child: const BoloXApp(),
    ),
  );
}

class BoloXApp extends StatelessWidget {
  const BoloXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoloX Radio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LandingScreen(),
    );
  }
}
