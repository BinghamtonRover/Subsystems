import "dart:async";

import "package:osc/osc.dart";

import "package:subsystems/subsystems.dart";
import "package:burt_network/burt_network.dart";

/// The serial port that the IMU is connected to.
const imuPort = "/dev/rover-imu";

extension on double {
  bool isZero([double epsilon = 0.01]) => abs() < epsilon;
}

/// A service to read orientation data from the connected IMU.
class ImuReader extends Service {
  /// The device that reads from the serial port. 
  final serial = SerialDevice(
    portName: imuPort, 
    readInterval: const Duration(milliseconds: 10),
    logger: logger,
  );

  /// The subscription that will be notified when a new serial packet arrives.
  StreamSubscription<List<int>>? subscription;

  /// Parses an OSC bundle from a list of bytes.
  void _handleOsc(List<int> data) {
    try {
      final message = OSCMessage.fromBytes(data.sublist(20));
      if (message.address != "/euler") return;
      final orientation = Orientation(
        x: message.arguments[0] as double,
        y: message.arguments[1] as double,
        z: message.arguments[2] as double,
      );
      if (orientation.x.isZero() || orientation.y.isZero() || orientation.z.isZero()) return;
      if (orientation.x.abs() > 360 || orientation.y.abs() > 360 || orientation.z.abs() > 360) return;
      final position = RoverPosition(orientation: orientation);
      collection.server.sendMessage(position);
    } catch (error) { /* Ignore corrupt data */ }
  }

  @override
  Future<bool> init() async {
    try {
      if (!await serial.init()) {
        logger.critical("Could not open IMU on port $imuPort");
        return false;
      }
      subscription = serial.stream.listen(_handleOsc);
      serial.startListening();
      logger.info("Reading IMU on port $imuPort");
      return true;
    } catch (error) {
      logger.critical("Could not open IMU", body: "Port $imuPort, Error: $error");
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await subscription?.cancel();
    await serial.dispose();
  }
}
