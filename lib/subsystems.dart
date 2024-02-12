import "package:burt_network/logging.dart";
import "package:subsystems/src/messages/serial.dart";

import "src/server.dart";
import "src/serial/gps.dart";
import "src/serial/imu.dart";
import "src/messages/can.dart";

export "src/server.dart";
export "src/serial/firmware.dart";
export "src/serial/imu.dart";
export "src/serial/serial.dart";
export "src/serial/gps.dart";
export "src/can/ffi.dart";
export "src/can/message.dart";
export "src/can/socket_ffi.dart";
export "src/can/socket_interface.dart";
export "src/can/socket_stub.dart";

/// Contains all the resources needed by the subsystems program.
class SubsystemsCollection {
	/// The CAN bus socket.
	final can = CanService();
  final serial = SerialService();
	/// The UDP server.
	final server = SubsystemsServer(port: 8001);
	/// The GPS reader.
	final gps = GpsReader();
  /// The IMU reader.
	final imu = ImuReader();

	/// Initializes all the resources needed by the subsystems.
	Future<void> init() async {
		logger.debug("Running in debug mode...");
		await server.init();
    try {
      await can.init();
      await serial.init();
      await gps.init();
      await imu.init();
      logger.info("Subsystems initialized");
    } catch (error) {
      logger.critical("Unexpected error when initializing Subsystems", body: error.toString());
    }
	}

	/// Disposes all the resources needed by the subsystems.
	Future<void> dispose() async {
		await can.dispose();
    await serial.dispose();
		await server.dispose();
    await imu.dispose();
		await gps.dispose();
		logger.info("Subsystems disposed");
	}
}

/// The collection of all the subsystem's resources.
final collection = SubsystemsCollection();
/// A logger that prints to the terminal and sends a UDP message.
final logger = BurtLogger(socket: collection.server);
