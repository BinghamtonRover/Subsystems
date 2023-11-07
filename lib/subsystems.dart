import "package:burt_network/logging.dart";
import "package:subsystems/can.dart";

import "src/server.dart";
import "src/serial/gps.dart";

export "src/server.dart";
export "src/serial/serial.dart";
export "src/serial/gps.dart";

/// Contains all the resources needed by the subsystems program.
class SubsystemsCollection {
	/// The CAN bus socket.
	final can = CanService();
	/// The UDP server.
	final server = SubsystemsServer(port: 8001);
	/// The GPS reader.
	final gps = GpsReader();

	/// Initializes all the resources needed by the subsystems.
	Future<void> init() async {
		logger.debug("Running in debug mode...");
		await can.init();
		await server.init();
		await gps.init();
		logger.info("Subsystems initialized");
	}

	/// Disposes all the resources needed by the subsystems.
	Future<void> dispose() async {
		can.dispose();
		await server.dispose();
		gps.dispose();
		logger.info("Subsystems disposed");
	}
}

/// The collection of all the subsystem's resources.
final collection = SubsystemsCollection();
