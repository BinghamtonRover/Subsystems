import "package:burt_network/logging.dart";

import "src/service.dart";
import "src/server.dart";
import "src/devices/gps.dart";
import "src/devices/imu.dart";
import "src/messages/can.dart";
import "src/messages/serial.dart";

export "src/service.dart";
export "src/server.dart";
export "src/devices/firmware.dart";
export "src/devices/imu.dart";
export "src/serial/serial.dart";
export "src/serial/port_interface.dart";
export "src/devices/gps.dart";
export "src/can/ffi.dart";
export "src/can/message.dart";
export "src/can/socket_ffi.dart";
export "src/can/socket_interface.dart";
export "src/can/socket_stub.dart";

/// Contains all the resources needed by the subsystems program.
class SubsystemsCollection extends Service {
	/// The CAN bus socket.
	final can = CanService();
  /// The Serial service.
  final serial = SerialService();
	/// The UDP server.
	final server = SubsystemsServer(port: 8001);
	/// The GPS reader.
	final gps = GpsReader();
  /// The IMU reader.
	final imu = ImuReader();

  @override
	Future<bool> init() async {
		logger.debug("Running in debug mode...");
		logger.trace("Running in trace mode...");
		await server.init();
    var result = true;
    try {
      result &= await can.init();
      result &= await serial.init();
      result &= await gps.init();
      result &= await imu.init();
      logger.info("Subsystems initialized");
      if (result) {
        logger.warning("The subsystems did not start properly");
      }
      return true;  // The subsystems should keep running even when something goes wrong.
    } catch (error) {
      logger.critical("Unexpected error when initializing Subsystems", body: error.toString());
      return false;
    }
	}

  @override
	Future<void> dispose() async {
    logger.info("Shutting down...");
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
