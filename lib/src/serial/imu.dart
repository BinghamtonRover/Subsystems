import "dart:convert";

import "package:osc/osc.dart";

import "package:subsystems/subsystems.dart";
import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";

const port = "/dev/ttyACM1";

extension on double {
  bool isZero([double epsilon = 0.001]) => this.abs() < epsilon;
}

class ImuReader {
  final SerialDevice serial = SerialDevice(portName: port, readInterval: Duration(milliseconds: 10));

  void parseOsc(List <int> data) {
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
        logger.warning("Got invalid orientation: x=${orientation.x}, y=${orientation.y}, z=${orientation.z}");
        return;
      }
      logger.debug("Got orientation: x=${orientation.x}, y=${orientation.y}, z=${orientation.z}");
      final position = RoverPosition(orientation: orientation);
      collection.server.sendMessage(position);
    } catch (error) { 
      final rawLine = utf8.decode(data.sublist(20), allowMalformed: true);
      logger.debug("Got invalid line from IMU: $rawLine");
    }
  }

  Future<void> init() async {
    serial.open();
    serial.stream.listen(parseOsc);
    logger.info("Reading IMU on port $port");
  }

  void dispose() {
    logger.info("ImuReader disposed");
  }
}
