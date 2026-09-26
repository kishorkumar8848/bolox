import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../../core/constants/theme.dart';
import '../../communication/communication_controller.dart';
import 'package:app_settings/app_settings.dart';

class OfflineSetupScreen extends StatefulWidget {
  const OfflineSetupScreen({super.key});

  @override
  State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
}

class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();
  
  Map<String, bool> _downloadStatus = {};
  bool _isDownloading = false;
  String _currentTask = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    for (String langName in CommunicationController.mlkitLanguages.keys) {
      TranslateLanguage lang = CommunicationController.mlkitLanguages[langName]!;
      bool isDownloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
      if (mounted) {
        setState(() {
          _downloadStatus[langName] = isDownloaded;
        });
      }
    }
  }

  Future<void> _downloadAllModels() async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    final languages = CommunicationController.mlkitLanguages.keys.toList();
    for (int i = 0; i < languages.length; i++) {
      String langName = languages[i];
      TranslateLanguage lang = CommunicationController.mlkitLanguages[langName]!;
      
      if (!(_downloadStatus[langName] ?? false)) {
        if (mounted) {
          setState(() {
            _currentTask = 'Downloading $langName...';
          });
        }
        try {
          await _modelManager.downloadModel(lang.bcpCode);
          _downloadStatus[langName] = true;
        } catch (e) {
          print('Failed to download $langName: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _progress = (i + 1) / languages.length;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _currentTask = 'All translation models downloaded!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allDownloaded = _downloadStatus.values.where((v) => v).length == CommunicationController.mlkitLanguages.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Offline Setup Manager'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '1. Download Translation Models',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Google ML Kit requires downloading these language packs once over Wi-Fi before they work in Airplane Mode.',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            if (_isDownloading) ...[
              Text(_currentTask, style: const TextStyle(color: AppTheme.primary)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress, color: AppTheme.primary, backgroundColor: AppTheme.surface),
            ] else ...[
              ElevatedButton.icon(
                onPressed: allDownloaded ? null : _downloadAllModels,
                icon: Icon(allDownloaded ? Icons.check_circle : Icons.download),
                label: Text(allDownloaded ? 'All Translation Models Cached' : 'Download Missing Models'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allDownloaded ? Colors.green : AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '2. Configure STT / TTS Hardware',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Since we are forcing Android to process speech on its internal hardware (onDevice: true) for the hackathon, you MUST download the Voice Typing packs in Android Settings.',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '• STT: Settings > Google Assistant > Offline Speech Recognition > Download languages.\n\n• TTS: Settings > Text-to-speech output > Google TTS Engine > Install voice data.',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                AppSettings.openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('OPEN ANDROID SETTINGS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
