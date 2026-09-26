abstract class CommunicationTransport {
  /// Initializes the transport mechanism
  Future<void> initialize();

  /// Starts advertising (Receiver role)
  Future<void> startAdvertising(String userName);

  /// Stops advertising
  Future<void> stopAdvertising();

  /// Starts discovery (Sender role)
  Future<void> startDiscovery(String userName);

  /// Stops discovery
  Future<void> stopDiscovery();

  /// Requests connection to a discovered endpoint
  Future<void> requestConnection(String endpointId, String userName);

  /// Accepts an incoming connection request
  Future<void> acceptConnection(String endpointId);

  /// Rejects an incoming connection request
  Future<void> rejectConnection(String endpointId);

  /// Disconnects from the current endpoint
  Future<void> disconnect();

  /// Sends a raw packet
  Future<void> sendPacket(List<int> data);

  /// Stream of incoming connection requests (endpointId, endpointName)
  Stream<Map<String, String>> get onConnectionInitiated;

  /// Stream of discovered endpoints (endpointId, endpointName)
  Stream<Map<String, String>> get onEndpointDiscovered;

  /// Stream of lost endpoints (endpointId)
  Stream<String> get onEndpointLost;

  /// Stream of incoming packets
  Stream<List<int>> get onPacketReceived;

  /// Stream representing the connection state
  Stream<bool> get onConnectionChanged;
  
  /// Human readable transport name (e.g. "Nearby Connections", "LoRa/RF")
  String get name;
}
