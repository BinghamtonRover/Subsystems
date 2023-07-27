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
	void onHeartbeat(Connect heartbeat, SocketInfo source) {
		super.onHeartbeat(heartbeat, source);
		print("Heartbeat from ${source.address}:${source.port}");
	}

	@override
	void onMessage(WrappedMessage wrapper) {
		collection.can.sendWrapper(wrapper);
	}
}
