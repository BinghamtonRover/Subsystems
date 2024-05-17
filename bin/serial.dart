import "dart:io";
import "dart:typed_data";
import "package:burt_network/burt_network.dart";
import "package:collection/collection.dart";
import "package:libserialport/libserialport.dart";

final logger = BurtLogger();

bool ascii = false;

Future<void> listenToDevice(String port) async {
  logger.info("Connecting to $port...");
  final device = SerialDevice(
    portName: port, 
    readInterval: const Duration(milliseconds: 100),
    logger: logger,
  );
  if (!await device.init()) {
    logger.critical("Could not connect to $port");
    return;
  }
  logger.info("Connected. Listening...");
  device.stream.listen(process);
  device.startListening();
}

Future<void> listenToFirmware(String port) async {
  logger.info("Connecting to $port...");
  final device = BurtFirmwareSerial(
    port: port, 
    logger: logger,
  );
  if (!await device.init()) {
    logger.critical("Could not connect to $port");
    return;
  }
  logger.info("Connected? ${device.isReady}. Listening...");
  device.stream?.listen(process);
}

typedef ProtoConstructor = Message Function(List<int> data);

ProtoConstructor? getDataConstructor(Device device) => switch (device) {
  Device.DRIVE => DriveData.fromBuffer,
  Device.ARM => ArmData.fromBuffer,
  Device.GRIPPER => GripperData.fromBuffer,
  Device.SCIENCE => GripperData.fromBuffer,
  _ => null,
};

ProtoConstructor? constructor;

void main(List<String> args) async {
  if (args.isEmpty) {
    logger.info("Ports: ${SerialPort.availablePorts}");
    return;
  } else if (args.contains("-h") || args.contains("--help")) {
    logger.info("Usage: dart run -r :serial [-a | --ascii] [port device]");
    return;
  }
  final deviceName = args.last;
  final device = Device.values.firstWhereOrNull((d) => d.name.toLowerCase() == deviceName.toLowerCase());
  if (device == null) {
    logger.error("Enter a device name as the last argument. Unrecognized device: $deviceName");
    return;
  }
  constructor = getDataConstructor(device);
  if (constructor == null) {
    logger.error("Unsupported serial device: $deviceName");
    return;
  }
  var port = args.first;
  if (!Platform.isWindows && !port.startsWith("/dev")) port = "/dev/$port";
  if (args.contains("-a") || args.contains("--ascii")) {
    logger.info("Running in ASCII mode");
    ascii = true;
  }
  if (args.contains("-f") || args.contains("--firmware")) {
    await listenToFirmware(port);
  } else {
    await listenToDevice(port);
  }
}

void process(Uint8List buffer) {
  if (ascii) {
    final s = String.fromCharCodes(buffer).trim();
    logger.debug("Got string: $s");	
  } else {
    try {
      final data = constructor!(buffer);
      logger.debug("Got data: ${data.toProto3Json()}");
    } catch (error) {
      logger.error("Could not decode DriveData: $error\n  Buffer: $buffer");
    }
  }
}
