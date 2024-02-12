import "dart:typed_data";

import "package:protobuf/protobuf.dart";
import "package:burt_network/generated.dart";
import "package:subsystems/subsystems.dart";

class BurtFirmwareSerial {
  static const readInterval = Duration(milliseconds: 100);
  static const handshakeDelay = Duration(milliseconds: 200);
  static final resetCode = Uint8List.fromList([0, 0, 0, 0]);
  Device device = Device.FIRMWARE;

  SerialDevice? _serial;

  final String port;
  BurtFirmwareSerial(this.port);

  Stream<Uint8List>? get stream => _serial?.stream;

  Future<void> init() async {
    // Open the port
    _serial = SerialDevice(portName: port, readInterval: readInterval);
    try {
      _serial!.open();
    } on SerialPortUnavailable {
      logger.critical("Could not open Serial port $port");
      return;
    }
    // Execute the handshake
    reset();
    if (await sendHandshake()) {
      logger.info("Connected to the ${device.name} Teensy");
    } else {
      logger.critical("Could not connect to Teensy", body: "Device on port $port failed the handshake");
    }
    // Forward data through the [stream].
    _serial!.startListening();
  }

  Future<bool> sendHandshake() async {
    final handshake = Connect(sender: Device.SUBSYSTEMS, receiver: Device.FIRMWARE); 
    _serial!.write(handshake.writeToBuffer());
    await Future<void>.delayed(handshakeDelay);
    final response = _serial!.readBytes(count: 4);
    if (response.isEmpty) return false;
    try {
      final message = Connect.fromBuffer(response);
      if (message.receiver != Device.SUBSYSTEMS) return false;
      device = message.sender;
      return true;
    } on InvalidProtocolBufferException {
      return false;
    }
  }

  bool reset() {
    _serial?.write(resetCode);
    final response = _serial?.readBytes(count: 4);
    if (response == null) return false;
    if (response.length != 4 || response.any((x) => x != 1)) return false;
    logger.info("The ${device.name} Teensy has been reset");
    return true;
  }

  void sendBytes(List<int> bytes) => _serial?.write(Uint8List.fromList(bytes));

  Future<void> dispose() async {
    reset();
    _serial?.dispose();
  }
}
