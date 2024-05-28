import "package:burt_network/burt_network.dart";

/// A service to send commands and receive data from a device.
/// The Dashboard and Autonomy programs only understand [WrappedMessage]s.
/// The Subsystems programs (teensys/arduinos) only understands [Message]s.
abstract class MessageService extends Service {
  /// Unwraps a [WrappedMessage] and sends it to the device 
  /// Takes in data from subsystems (teensys) and sends it to the dashboard/autonomy
  /// Sends Command classes ([DriveCommand], [ArmCommand], [GripperCommand], etc.)
  void sendWrapper(WrappedMessage wrapper);

  /// Wraps a message and sends it using [sendWrapper].
  /// Sends an incoming wrapped message from dashboard or autonomy to the subsystems (teensys)
  /// Sends Data classes ([DriveData], [ArmData], [GripperData], etc.)
  void sendMessage(Message message) => sendWrapper(message.wrap());
}
