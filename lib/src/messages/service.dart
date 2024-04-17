import "package:burt_network/burt_network.dart";

/// A service to send commands and receive data from a device.
abstract class MessageService extends Service {
  /// Unwraps a [WrappedMessage] and sends it to the device, 
  void sendWrapper(WrappedMessage wrapper);

  /// Wraps a message and sends it using [sendWrapper].
  void sendMessage(Message message) => sendWrapper(message.wrap());
}
