import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

abstract class SpeechEncoder {
  Future<Uint8List> encode(Uint8List pcmAudio);
  int getBitrate();
  int getModelSize();
  List<int> getSupportedModes();
}

class EnCodecOnnxEncoder implements SpeechEncoder {
  OrtSession? _session;
  int _currentBitrate = 3; // 3 kbps

  void setBitrate(int kbps) {
    _currentBitrate = kbps;
  }

  Future<void> initialize() async {
    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();
      final rawAssetFile = await rootBundle.load('assets/models/encodec.onnx');
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      print('EnCodec ONNX model loaded successfully.');
    } catch (e) {
      print('Warning: Dummy EnCodec model load failed. Replace with real weights. Error: $e');
    }
  }

  @override
  Future<Uint8List> encode(Uint8List pcmAudio) async {
    if (_session == null) return Uint8List(1); // Fallback byte

    // In a real implementation:
    // 1. Convert PCM to Float32List
    // 2. _session.run(runOptions, {'audio': tensor})
    // 3. Extract the discrete latent codes (integers)
    // 4. Pack into bitstream (Uint8List)
    
    await Future.delayed(const Duration(milliseconds: 20));
    
    // Simulate compression based on bitrate
    int compressedSize = pcmAudio.length ~/ (16 ~/ _currentBitrate); 
    if (compressedSize <= 0) compressedSize = 1;
    return Uint8List(compressedSize);
  }

  @override
  int getBitrate() => _currentBitrate;

  @override
  int getModelSize() => 15000000; // 15MB mock size

  @override
  List<int> getSupportedModes() => [1, 2, 3]; // 1 kbps, 2 kbps, 3 kbps
}
