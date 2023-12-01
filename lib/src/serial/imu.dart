import "dart:async";
import "dart:convert";

import "package:osc/osc.dart";

import "package:subsystems/subsystems.dart";
import "package:burt_network/burt_network.dart";

/// The serial port that the IMU is conncted to.
const port = "/dev/rover-imu";

extension on double {
  bool isZero([double epsilon = 0.001]) => abs() < epsilon;
}

/// A service to read orientation data from the connected IMU.
class ImuReader {
  /// The device that reads from the serial port. 
  final serial = SerialDevice(portName: port, readInterval: const Duration(milliseconds: 10));

  /// The subscription that will be notified when a new serial packet arrives.
  StreamSubscription<List<int>>? subscription;

  /// Parses an OSC bundle from a list of bytes.
  void handleOsc(List<int> data) {
    try {
      final message = OSCMessage.fromBytes(data.sublist(20));
      logger.debug("Received: $message");    
      final orientation = Orientation(
        x: message.arguments[0] as double,
        y: message.arguments[1] as double,
        z: message.arguments[2] as double,
      );
      if (orientation.x.isZero() || orientation.y.isZero() || orientation.z.isZero()) return;
      if (orientation.x > 360 || orientation.y > 360 || orientation.z > 360) {
        logger.warning("Got invalid orientation from IMU", body: "x=${orientation.x}, y=${orientation.y}, z=${orientation.z}");
        return;
      }
      logger.debug("Got orientation: x=${orientation.x}, y=${orientation.y}, z=${orientation.z}");
      final position = RoverPosition(orientation: orientation);
      collection.server.sendMessage(position);
    } catch (error) { 
      final rawLine = utf8.decode(data.sublist(20), allowMalformed: true);
      logger.debug("Got invalid line from IMU", body: rawLine);
    }
  }

  /// Starts listening to the IMU.
  Future<void> init() async {
    try {
      serial.open();
      subscription = serial.stream.listen(handleOsc);
      logger.info("Reading IMU on port $port");
    } catch (error) {
      logger.critical("Could not open IMU", body: "Port $port, Error: $error");
    }
  }

  /// Stops listening to the serial port.
  void dispose() {
    subscription?.cancel();
  }
}
