import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';

abstract class OfflineTTS {
  Future<void> initialize(String language);
  Future<void> speak(String text);
  void stop();
  List<String> getSupportedLanguages();
}

class NativeTTS implements OfflineTTS {
  final FlutterTts _flutterTts = FlutterTts();
  
  static const List<String> _languages = [
    'Hindi', 'Gujarati', 'Marathi', 'Kannada', 'Malayalam', 
    'Tamil', 'Telugu', 'Odia', 'Bengali', 'English'
  ];

  @override
  Future<void> initialize(String languageCode) async {
    try {
      // Convert from STT locale (ta_IN) to TTS locale (ta-IN)
      final ttsCode = languageCode.replaceAll('_', '-');
      await _flutterTts.setLanguage(ttsCode);
      
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      print('FlutterTTS initialized for $ttsCode.');
    } catch (e) {
      print('FlutterTTS initialization failed: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void stop() async {
    await _flutterTts.stop();
  }

  @override
  List<String> getSupportedLanguages() => _languages;
}
