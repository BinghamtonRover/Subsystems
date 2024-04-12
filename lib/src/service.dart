import "package:burt_network/burt_network.dart";

/// A class that represents a connection to some other API, service, or device.
abstract class Service {
  /// Initializes the connection to the device.
  Future<bool> init();

  /// Closes the connection to the device.
  Future<void> dispose(); 
}

/// A service to send commands and receive data from a device.
abstract class MessageService extends Service {
  /// Unwraps a [WrappedMessage] and sends it to the device, 
  void sendWrapper(WrappedMessage wrapper);
}
