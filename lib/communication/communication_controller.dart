import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'communication_transport.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:geolocator/geolocator.dart';
import 'packet.dart';
import 'packetizer.dart';
import '../speech/audio_manager.dart';
import '../speech/offline_stt.dart';
import '../speech/offline_tts.dart';
import '../adaptive/bitrate_controller.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

enum Role { sender, receiver, unassigned }

class CommunicationController extends ChangeNotifier {
  final CommunicationTransport transport;
  final AudioManager audioManager;
  final NativeSTT stt;
  final NativeTTS tts;
  final AdaptiveBitrateController bitrateController;

  Role role = Role.receiver;
  bool isConnected = false;
  bool isTransmitting = false;
  bool isReceiving = false;
  bool isDuplexMode = false;
  String currentLanguage = 'English';
  String latestPartialText = ''; // To display live transcription on UI
  String? peerLocation; // Stores received location

  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();
  OnDeviceTranslator? _translator;
  String? _lastSourceLanguage;
  String? _lastTargetLanguage;

  static const Map<String, String> sttLocales = {
    'Hindi': 'hi_IN',
    'Gujarati': 'gu_IN',
    'Marathi': 'mr_IN',
    'Kannada': 'kn_IN',
    'Malayalam': 'ml_IN',
    'Tamil': 'ta_IN',
    'Telugu': 'te_IN',
    'Odia': 'or_IN',
    'Bengali': 'bn_IN',
    'English': 'en_US',
  };

  static const Map<String, TranslateLanguage> mlkitLanguages = {
    'Hindi': TranslateLanguage.hindi,
    'Gujarati': TranslateLanguage.gujarati,
    'Marathi': TranslateLanguage.marathi,
    'Kannada': TranslateLanguage.kannada,
    'Tamil': TranslateLanguage.tamil,
    'Telugu': TranslateLanguage.telugu,
    'Bengali': TranslateLanguage.bengali,
    'English': TranslateLanguage.english,
    // Add missing languages. Fallback Odia and Malayalam to English since they are unsupported in this MLKit version.
    'Malayalam': TranslateLanguage.english,
    'Odia': TranslateLanguage.english, 
  };

  int _sessionId = 0;
  int _sequenceNumber = 0;
  
  // Buffer for assembling chunked audio payloads
  final Map<int, Map<int, Uint8List>> _audioBuffers = {};
  StreamSubscription? _transportSub;
  StreamSubscription? _connectionInitSub;

  // Callback for UI to show accept/reject dialog
  void Function(String endpointId, String endpointName)? onIncomingConnection;
  CommunicationController({
    required this.transport,
    required this.audioManager,
    required this.stt,
    required this.tts,
    required this.bitrateController,
  }) {
    stt.initialize();
    tts.initialize('English');
    _transportSub = transport.onPacketReceived.listen(_handleIncomingPacket);
    transport.onConnectionChanged.listen((connected) {
      isConnected = connected;
      notifyListeners();
    });
    _connectionInitSub = transport.onConnectionInitiated.listen((event) {
      if (role == Role.receiver && onIncomingConnection != null) {
        onIncomingConnection!(event['endpointId']!, event['endpointName']!);
      }
    });
  }

  void setRole(Role newRole) {
    role = newRole;
    notifyListeners();
  }

  Future<void> setLanguage(String newLanguage) async {
    currentLanguage = newLanguage;
    tts.initialize(sttLocales[newLanguage] ?? 'en_US');
    notifyListeners();
    
    // Download the model for the selected language if not present
    final lang = mlkitLanguages[newLanguage];
    if (lang != null) {
      print('Downloading ML model for $newLanguage...');
      await _modelManager.downloadModel(lang.bcpCode);
      print('Model for $newLanguage is ready.');
    }
  }

  Future<void> startAdvertising(String userName) async {
    await transport.startAdvertising(userName);
  }

  Future<void> startDiscovery(String userName) async {
    await transport.startDiscovery(userName);
  }

  Future<void> requestConnection(String endpointId, String userName) async {
    await transport.requestConnection(endpointId, userName);
  }

  Future<void> acceptConnection(String endpointId) async {
    await transport.acceptConnection(endpointId);
  }

  Future<void> rejectConnection(String endpointId) async {
    await transport.rejectConnection(endpointId);
  }

  Future<void> disconnect() async {
    await transport.disconnect();
    isConnected = false;
    notifyListeners();
  }

  String _getCompassDirection(double bearing) {
    if (bearing < 0) bearing += 360;
    if (bearing >= 337.5 || bearing < 22.5) return 'North';
    if (bearing >= 22.5 && bearing < 67.5) return 'North-East';
    if (bearing >= 67.5 && bearing < 112.5) return 'East';
    if (bearing >= 112.5 && bearing < 157.5) return 'South-East';
    if (bearing >= 157.5 && bearing < 202.5) return 'South';
    if (bearing >= 202.5 && bearing < 247.5) return 'South-West';
    if (bearing >= 247.5 && bearing < 292.5) return 'West';
    if (bearing >= 292.5 && bearing < 337.5) return 'North-West';
    return 'Unknown';
  }

  void toggleDuplexMode() {
    isDuplexMode = !isDuplexMode;
    // Send a control packet to sync mode with the peer
    if (isConnected) {
      _sendTextPacket(isDuplexMode ? "MODE_PHONE" : "MODE_WT", codecMode: 5);
    }
    notifyListeners();
  }

  void _syncDuplexModeFromPeer(String command) {
    bool newMode = command == "MODE_PHONE";
    if (isDuplexMode != newMode) {
      isDuplexMode = newMode;
      notifyListeners();
    }
  }

  Future<void> sendLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      peerLocation = "Error: Location services disabled on peer.";
      notifyListeners();
      return;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      String locationData = "${position.latitude},${position.longitude}";
      _sendTextPacket(locationData, codecMode: 4);
    } catch (e) {
      print("Location error: $e");
    }
  }

  void sendEmergencyAlert() {
    _sendTextPacket("EMERGENCY ALERT: ASSISTANCE REQUIRED", codecMode: 99);
  }

  Future<void> startPtt() async {
    // Both sender and receiver can transmit in this design
    if (!isConnected || isTransmitting) return;

    isTransmitting = true;
    _sessionId = DateTime.now().millisecondsSinceEpoch % 65535;
    _sequenceNumber = 0;
    notifyListeners();

    _startContinuousListening();
  }

  Future<void> _startContinuousListening() async {
    if (!isTransmitting) return;

    final localeId = sttLocales[currentLanguage] ?? 'en_US';
    await stt.startListening(
      localeId: localeId,
      onPartialResult: (text) {
        _sendTextPacket(text, codecMode: 3); // codecMode 3 for partial stream
      },
    );

    // If in duplex mode, we need to handle when native STT naturally times out
    // and restart it to keep the "call" alive.
    if (isDuplexMode) {
      Future.delayed(const Duration(seconds: 5), () async {
        if (isTransmitting) {
          final text = await stt.stopListening();
          _sendTextPacket(text, codecMode: 2);
          _startContinuousListening(); // loop
        }
      });
    }
  }

  void _sendTextPacket(String text, {int codecMode = 2}) async {
    if (text.isEmpty) return;
    
    final textBytes = utf8.encode(text);
    final languageIndex = mlkitLanguages.keys.toList().indexOf(currentLanguage);

    final packet = RadioPacket(
      sourceId: 1,
      destId: 2,
      sessionId: _sessionId,
      sequenceNumber: _sequenceNumber++,
      frameId: 0,
      codecMode: codecMode,
      bitrateMode: languageIndex >= 0 ? languageIndex : 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: Uint8List.fromList(textBytes),
    );

    final transmitData = Packetizer.encode(packet);
    await transport.sendPacket(transmitData);
  }

  Future<void> stopPtt() async {
    if (!isTransmitting) return;

    final text = await stt.stopListening();
    _sendTextPacket(text, codecMode: 2); // codecMode 2 for final text

    isTransmitting = false;
    notifyListeners();
  }

  void _handleIncomingPacket(List<int> rawData) async {
    final packet = Packetizer.decode(Uint8List.fromList(rawData));
    if (packet == null) {
      bitrateController.recordPacketLoss();
      return;
    }

    isReceiving = true;
    notifyListeners();

    try {
      if (packet.codecMode == 1) { // Chunked Audio
        final sessionId = packet.sessionId;
        final chunkIndex = packet.frameId;
        final totalChunks = packet.bitrateMode;

        _audioBuffers.putIfAbsent(sessionId, () => {});
        _audioBuffers[sessionId]![chunkIndex] = packet.payload;

        print('Received audio chunk $chunkIndex/$totalChunks for session $sessionId');

        if (_audioBuffers[sessionId]!.length == totalChunks) {
          final builder = BytesBuilder();
          for (int i = 0; i < totalChunks; i++) {
            if (_audioBuffers[sessionId]![i] != null) {
              builder.add(_audioBuffers[sessionId]![i]!);
            }
          }
          final completeAudio = builder.toBytes();
          _audioBuffers.remove(sessionId);
          
          print('Assembled complete audio payload: ${completeAudio.length} bytes');
          await audioManager.playAudio(completeAudio);
        }
      } else if (packet.codecMode == 3) {
        // Partial text received
        final incomingText = utf8.decode(packet.payload);
        latestPartialText = incomingText;
        notifyListeners();
      } else if (packet.codecMode == 4) {
        // Location Update
        final incomingLocation = utf8.decode(packet.payload);
        try {
          final parts = incomingLocation.split(',');
          if (parts.length == 2) {
            double peerLat = double.parse(parts[0]);
            double peerLon = double.parse(parts[1]);
            
            Position localPos = await Geolocator.getCurrentPosition();
            double distance = Geolocator.distanceBetween(localPos.latitude, localPos.longitude, peerLat, peerLon);
            double bearing = Geolocator.bearingBetween(localPos.latitude, localPos.longitude, peerLat, peerLon);
            String direction = _getCompassDirection(bearing);
            
            String distStr = distance > 1000 
                ? '${(distance / 1000).toStringAsFixed(1)} km' 
                : '${distance.toStringAsFixed(0)} meters';
                
            peerLocation = '$distStr $direction';
          } else {
            peerLocation = incomingLocation;
          }
        } catch (e) {
          peerLocation = incomingLocation;
        }
        notifyListeners();
      } else if (packet.codecMode == 5) {
        // Sync Duplex Mode
        final command = utf8.decode(packet.payload);
        _syncDuplexModeFromPeer(command);
      } else if (packet.codecMode == 99) {
        // Emergency Alert
        final incomingText = utf8.decode(packet.payload);
        print('Received EMERGENCY Transmission: $incomingText');
        latestPartialText = incomingText;
        notifyListeners();
        
        // Force max volume
        try {
          await PerfectVolumeControl.setVolume(1.0);
        } catch (e) {
          print('Volume override failed: $e');
        }
        
        await tts.speak(incomingText);
      } else if (packet.codecMode == 2) {
        final incomingText = utf8.decode(packet.payload);
        final latency = DateTime.now().millisecondsSinceEpoch - packet.timestamp;
        bitrateController.metricsService.recordLatency(latency);
        print('Received Semantic Transmission in ${latency}ms: $incomingText');
        latestPartialText = incomingText; // final text
        notifyListeners();
        
        // Translate text to receiver's language
        final languagesList = mlkitLanguages.keys.toList();
        final sourceLanguageName = (packet.bitrateMode >= 0 && packet.bitrateMode < languagesList.length) 
            ? languagesList[packet.bitrateMode] 
            : 'English';

        final sourceLang = mlkitLanguages[sourceLanguageName] ?? TranslateLanguage.english;
        final targetLang = mlkitLanguages[currentLanguage] ?? TranslateLanguage.english;

        if (sourceLang != targetLang) {
          if (_translator == null || _lastSourceLanguage != sourceLanguageName || _lastTargetLanguage != currentLanguage) {
            _translator?.close();
            _translator = OnDeviceTranslator(sourceLanguage: sourceLang, targetLanguage: targetLang);
            _lastSourceLanguage = sourceLanguageName;
            _lastTargetLanguage = currentLanguage;
          }

          final translatedText = await _translator!.translateText(incomingText);
          print('Translated from $sourceLanguageName to $currentLanguage: $translatedText');
          await tts.speak(translatedText);
        } else {
          // Same language, no translation needed
          await tts.speak(incomingText);
        }
      }
    } catch (e) {
      print('Error decoding payload: $e');
    }

    // Reset UI state
    Future.delayed(const Duration(milliseconds: 500), () {
      isReceiving = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _transportSub?.cancel();
    _connectionInitSub?.cancel();
    audioManager.dispose();
    _translator?.close();
    super.dispose();
  }
}
