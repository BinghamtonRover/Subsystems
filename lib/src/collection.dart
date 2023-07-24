import "package:burt_network/burt_network.dart";

import "can.dart";
import "udp.dart";

/// Contains all the resources needed by the subsystems program.
class SubsystemsCollection {
	/// The CAN bus socket.
	final Can can = Can();
	/// The UDP server.
	final SubsystemsServer server = SubsystemsServer(port: 8001);

	/// Initializes all the resources needed by the subsystems.
	Future<void> init() async {
		await can.init();
		await server.init();
		logger.info("Subsystems initialized");
	}

	/// Disposes all the resources needed by the subsystems.
	Future<void> dispose() async {
		await can.dispose();
		await server.dispose();
		logger.info("Subsystems disposed");
	}
}

/// The collection of all the subsystem's resources.
final collection = SubsystemsCollection();
