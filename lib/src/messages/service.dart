import "package:burt_network/burt_network.dart";

/// A service to send commands and receive data from a device.
abstract class MessageService {
  /// Initializes the connection to the device.
  Future<void> init();
  /// Closes the connection to the device.
  Future<void> dispose();  

  /// Unwraps a [WrappedMessage] and sends it to the device, 
  void sendWrapper(WrappedMessage wrapper);
}
