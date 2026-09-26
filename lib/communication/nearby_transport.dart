import 'dart:async';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'communication_transport.dart';

class NearbyTransport implements CommunicationTransport {
  final Strategy strategy = Strategy.P2P_STAR;
  String? _connectedEndpointId;
  
  final StreamController<List<int>> _packetStreamController = StreamController.broadcast();
  final StreamController<bool> _connectionStreamController = StreamController.broadcast();
  final StreamController<Map<String, String>> _onConnectionInitiatedController = StreamController.broadcast();
  final StreamController<Map<String, String>> _onEndpointDiscoveredController = StreamController.broadcast();
  final StreamController<String> _onEndpointLostController = StreamController.broadcast();
  
  @override
  String get name => 'Nearby Connections';

  @override
  Stream<List<int>> get onPacketReceived => _packetStreamController.stream;

  @override
  Stream<bool> get onConnectionChanged => _connectionStreamController.stream;

  @override
  Stream<Map<String, String>> get onConnectionInitiated => _onConnectionInitiatedController.stream;

  @override
  Stream<Map<String, String>> get onEndpointDiscovered => _onEndpointDiscoveredController.stream;

  @override
  Stream<String> get onEndpointLost => _onEndpointLostController.stream;

  @override
  Future<void> initialize() async {
    // Requires Permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses[Permission.location] != PermissionStatus.granted) {
      print('Location permission not granted');
    }

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print('Could not turn on bluetooth automatically: $e');
    }
  }

  @override
  Future<void> startAdvertising(String userName) async {
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _onConnectionInitiatedController.add({
            'endpointId': id,
            'endpointName': info.endpointName,
          });
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            _connectedEndpointId = id;
            _connectionStreamController.add(true);
          } else {
            _connectionStreamController.add(false);
          }
        },
        onDisconnected: (String id) {
          _connectedEndpointId = null;
          _connectionStreamController.add(false);
        },
      );
    } catch (e) {
      print('Advertising failed: $e');
    }
  }

  @override
  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  @override
  Future<void> startDiscovery(String userName) async {
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (String id, String name, String serviceId) {
          _onEndpointDiscoveredController.add({
            'endpointId': id,
            'endpointName': name,
          });
        },
        onEndpointLost: (String? id) {
          if (id != null) {
            _onEndpointLostController.add(id);
          }
        },
      );
    } catch (e) {
      print('Discovery failed: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
  }

  @override
  Future<void> requestConnection(String endpointId, String userName) async {
    try {
      await Nearby().requestConnection(
        userName,
        endpointId,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _onConnectionInitiatedController.add({
            'endpointId': id,
            'endpointName': info.endpointName,
          });
          // Auto-accept on sender side
          acceptConnection(id);
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            _connectedEndpointId = id;
            _connectionStreamController.add(true);
          } else {
            _connectionStreamController.add(false);
          }
        },
        onDisconnected: (String id) {
          _connectedEndpointId = null;
          _connectionStreamController.add(false);
        },
      );
    } catch (e) {
      print('Request connection failed: $e');
    }
  }

  @override
  Future<void> acceptConnection(String endpointId) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (String endpointId, Payload payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          _packetStreamController.add(payload.bytes!.toList());
        }
      },
      onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate payloadTransferUpdate) {},
    );
  }

  @override
  Future<void> rejectConnection(String endpointId) async {
    await Nearby().rejectConnection(endpointId);
  }

  @override
  Future<void> disconnect() async {
    if (_connectedEndpointId != null) {
      await Nearby().disconnectFromEndpoint(_connectedEndpointId!);
      _connectedEndpointId = null;
    }
    await Nearby().stopAllEndpoints();
    _connectionStreamController.add(false);
  }

  @override
  Future<void> sendPacket(List<int> data) async {
    if (_connectedEndpointId != null) {
      await Nearby().sendBytesPayload(_connectedEndpointId!, Uint8List.fromList(data));
    } else {
      print('Cannot send data, not connected');
    }
  }
}
