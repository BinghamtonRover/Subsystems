import "package:burt_network/burt_network.dart";

abstract class MessageService {
  Future<void> init();
  Future<void> dispose();  

  void sendWrapper(WrappedMessage wrapper);
}
