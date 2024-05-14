import "package:burt_network/burt_network.dart";

import "package:subsystems/subsystems.dart";

/// A UDP server to connect to the dashboard.
/// 
/// This server should collect all commands that come in and forward them to the 
/// appropriate CAN device. All CAN messages should be forwarded to this server.
class SubsystemsServer extends RoverServer {
	/// Creates a Subsystems server on the given port.
	SubsystemsServer({required super.port}) : super(device: Device.SUBSYSTEMS);

	@override
	void onMessage(WrappedMessage wrapper) {
    if (wrapper.name == RoverPosition().messageName) return;
    collection.sendWrapper(wrapper);
	}

  @override
  Future<void> restart() async {
    await collection.dispose();
    await collection.init();
  }

  @override
  void onDisconnect() {
    super.onDisconnect();
    collection.stopHardware();
  }

  @override
  Future<void> onShutdown() => collection.dispose();
}
