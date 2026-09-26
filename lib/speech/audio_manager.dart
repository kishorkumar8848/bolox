import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioManager {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordFilePath;

  Future<void> initialize() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      print('Microphone permission not granted');
    }
    
    final tempDir = await getTemporaryDirectory();
    _recordFilePath = '${tempDir.path}/bolox_transmission.m4a';
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.isRecording()) return;

    if (_recordFilePath == null) {
      await initialize();
    }

    final config = const RecordConfig(
      encoder: AudioEncoder.aacLc, // AAC is widely supported and very compressed
      bitRate: 32000,
    );

    // Delete old file if it exists
    final file = File(_recordFilePath!);
    if (await file.exists()) {
      await file.delete();
    }

    await _audioRecorder.start(config, path: _recordFilePath!);
  }

  Future<Uint8List?> stopRecording() async {
    final path = await _audioRecorder.stop();
    
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }

  Future<void> playAudio(Uint8List audioData) async {
    try {
      print('Playing received audio: ${audioData.length} bytes');
      final tempDir = await getTemporaryDirectory();
      final playFilePath = '${tempDir.path}/bolox_receive.m4a';
      final file = File(playFilePath);
      await file.writeAsBytes(audioData, flush: true);
      
      await _audioPlayer.play(DeviceFileSource(playFilePath));
    } catch (e) {
      print('Failed to play audio: $e');
    }
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
