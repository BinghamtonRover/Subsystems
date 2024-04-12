import "package:burt_network/generated.dart";

import "../service.dart";

/// A service to send commands and receive data from a device.
abstract class MessageService extends Service {
  /// Unwraps a [WrappedMessage] and sends it to the device, 
  void sendWrapper(WrappedMessage wrapper);
}
