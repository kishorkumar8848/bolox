import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

abstract class OfflineSTT {
  Future<void> initialize();
  Future<void> startListening({String localeId = 'en_US', void Function(String text)? onPartialResult});
  Future<String> stopListening();
  List<String> getSupportedLanguages();
  void release();
}

class NativeSTT implements OfflineSTT {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  static const List<String> _languages = [
    'Hindi', 'Gujarati', 'Marathi', 'Kannada', 'Malayalam', 
    'Tamil', 'Telugu', 'Odia', 'Bengali', 'English'
  ];

  @override
  Future<void> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) => print('STT Error: $val'),
        onStatus: (val) => print('STT Status: $val'),
      );
      print('SpeechToText initialized: $_speechEnabled');
    } catch (e) {
      print('SpeechToText initialization failed: $e');
    }
  }

  @override
  Future<void> startListening({String localeId = 'en_US', void Function(String text)? onPartialResult}) async {
    _lastWords = '';
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          print('Recognized: $_lastWords');
          if (onPartialResult != null) {
            onPartialResult(_lastWords);
          }
        },
        listenMode: ListenMode.dictation,
        localeId: localeId,
        onDevice: true, // Forces Android to use offline downloaded language packs
      );
    } else {
      print('Speech is not enabled');
    }
  }

  @override
  Future<String> stopListening() async {
    if (_speechEnabled) {
      await _speechToText.stop();
      // Add a slight delay to allow final recognition result to stream in
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return _lastWords;
  }

  @override
  List<String> getSupportedLanguages() => _languages;

  @override
  void release() {
    _speechToText.cancel();
  }
}
