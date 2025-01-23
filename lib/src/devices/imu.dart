import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:collection/collection.dart";
import "package:osc/osc.dart";

import "package:subsystems/subsystems.dart";
import "package:burt_network/burt_network.dart";

/// The serial port that the IMU is connected to.
const imuPort = "/dev/rover-imu";

/// The version that we are using for [RoverPosition] data.
final positionVersion = Version(major: 1, minor: 0);

/// A service to read orientation data from the connected IMU.
class ImuReader extends Service {
  /// Frame end
  static const end = 192;
  /// Frame esc
  static const esc = 219;
  /// Transposed frame end
  static const escEnd = 220;
  /// Transposed frame escape
  static const escEsc = 221;

  /// The bytes of the OSC message #bundle header
  static Uint8List bundleHeader = const Utf8Encoder().convert("#bundle");

  /// The device that reads from the serial port.
  final serial = SerialDevice(
    portName: imuPort,
    readInterval: const Duration(milliseconds: 10),
    logger: logger,
  );

  /// The subscription that will be notified when a new serial packet arrives.
  StreamSubscription<List<int>>? subscription;
  StreamSubscription<SubsystemsCommand>? _commandSubscription;

  /// Parses an OSC bundle from a list of bytes.
  OSCMessage? parseOsc(List<int> data) {
    try {
      List<int> buffer;
      // If multiple messages are sent at once, it won't have the #bundle header
      final hasHeader = data.length > bundleHeader.length &&
          data.sublist(0, bundleHeader.length).equals(bundleHeader);
      if (hasHeader) {
        // skip 8 byte "#bundle" + 8 byte timestamp + 4 byte data length
        buffer = data.sublist(20);
      } else {
        buffer = data;
      }
      return OSCMessage.fromBytes(buffer);
    } catch (error) {
      /* Ignore corrupt data */
      return null;
    }
  }

  /// Handles an incoming [SubsystemsCommand]
  void handleCommand(SubsystemsCommand command) {
    if (command.zeroIMU && serial.isOpen) {
      serial.write(encodeSlip(OSCMessage("/ahrs/zero", arguments: []).toBytes()));
    }
  }

  /// Handles incoming serial bytes
  void handleSerial(List<int> bytes) {
    for (final packet in bytes.splitAfter((element) => element == end)) {
      final message = parseOsc(decodeSlip(packet));
      if (message == null) {
        continue;
      }
      if (message.address == "/button") {
        handleCommand(SubsystemsCommand(zeroIMU: true));
      }
      if (message.address == "/ahrs/zero") {
        // signal that the zero was received and processed
        if (serial.isOpen) {
          serial.write(encodeSlip(OSCMessage("/identify", arguments: []).toBytes()));
        }
        // send a duplicate of a subsystems command as a "handshake"
        collection.server.sendMessage(SubsystemsCommand(zeroIMU: true));
      }
      if (message.address == "/euler") {
        final orientation = Orientation(
          x: message.arguments[0] as double,
          y: message.arguments[1] as double,
          z: message.arguments[2] as double,
        );
        final position = RoverPosition(orientation: orientation, version: positionVersion);
        collection.server.sendMessage(position);
        collection.server.sendMessage(position, destination: autonomySocket);
      }
    }
  }

  /// Adds bytes as specified the SLIP protocol.
  ///
  /// This function is here until `package:osc` supports SLIP, mandated by the OSC v1.1 spec.
  /// See this issue: https://github.com/pq/osc/issues/24
  /// See: https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol
  Uint8List encodeSlip(List<int> data) {
    final newPacket = <int>[];
    for (final element in data) {
      if (element == end) {
        newPacket.addAll([esc, escEnd]);
      } else if (element == esc) {
        newPacket.addAll([esc, escEsc]);
      } else {
        newPacket.add(element);
      }
    }
    newPacket.add(end);
    return Uint8List.fromList(newPacket);
  }

  /// Removes bytes inserted by the SLIP protocol.
  ///
  /// This function is here until `package:osc` supports SLIP, mandated by the OSC v1.1 spec.
  /// See this issue: https://github.com/pq/osc/issues/24
  /// See: https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol
  Uint8List decodeSlip(List<int> data) {
    final newPacket = <int>[];
    var prevElement = 0;
    for (final element in data) {
      if (prevElement == esc && element == escEnd) {
        newPacket.last = end;  // ESC + ESC_END -> END
      } else if (prevElement == esc && element == escEsc) {
        newPacket.last = esc;  // ESC + ESC_ESC -> ESC
      } else {
        newPacket.add(element);
      }
      prevElement = element;
    }
    if (newPacket.last == end) newPacket.removeLast();
    return Uint8List.fromList(newPacket);
  }

  @override
  Future<bool> init() async {
    try {
      if (!await serial.init()) {
        logger.critical("Could not open IMU on port $imuPort");
        return false;
      }
      subscription = serial.stream.listen(handleSerial);
      _commandSubscription = collection.server.messages.onMessage(
        name: SubsystemsCommand().messageName,
        constructor: SubsystemsCommand.fromBuffer,
        callback: handleCommand,
      );
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
    await _commandSubscription?.cancel();
    await serial.dispose();
  }
}
