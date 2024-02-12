import "package:burt_network/burt_network.dart";

import "package:subsystems/subsystems.dart";

/// A UDP server to connect to the dashboard.
/// 
/// This server should collect all commands that come in and forward them to the 
/// appropriate CAN device. All CAN messages should be forwarded to this server.
class SubsystemsServer extends ServerSocket {
	/// Creates a Subsystems server on the given port.
	SubsystemsServer({required super.port}) : super(device: Device.SUBSYSTEMS);

  @override
  Future<void> updateSettings(UpdateSetting settings) async {
    super.updateSettings(settings);
    if (settings.status == RoverStatus.RESTART) {
      await collection.dispose();
      await Future<void>.delayed(const Duration(seconds: 1));
      await collection.init();
    }
  }

	@override
	void onMessage(WrappedMessage wrapper) {
    if (collection.serial.sendWrapper(wrapper)) return;
    collection.can.sendWrapper(wrapper);
	}
}
