import "dart:async";
import "dart:io";
import "dart:typed_data";
import "package:libserialport/libserialport.dart";

import "package:collection/collection.dart";
import "package:burt_network/generated.dart";
import "package:subsystems/subsystems.dart";

import "service.dart";

final nameToDevice = <String, Device>{
  ArmCommand().messageName: Device.ARM,
  GripperCommand().messageName: Device.GRIPPER,
  ElectricalCommand().messageName: Device.ELECTRICAL,
  DriveCommand().messageName: Device.DRIVE,
  ScienceCommand().messageName: Device.SCIENCE,
};

class SerialService extends MessageService {
	Future<List<BurtFirmwareSerial>> getFirmware() async {
		final imuCommand = await Process.run("realpath", ["/dev/rover-imu"]);
		final imuPort = imuCommand.stdout.trim();
		logger.trace("IMU is on: $imuPort");
		final gpsCommand = await Process.run("realpath", ["/dev/rover-gps"]);
		final gpsPort = gpsCommand.stdout.trim();
		logger.trace("GPS is on: $gpsPort");
		return [
			for (final port in SerialPort.availablePorts)
				if (port != imuPort && port != gpsPort)
					BurtFirmwareSerial(port),
		];
	}

  final List<StreamSubscription<Uint8List>> _subscriptions = [];
  List<BurtFirmwareSerial> devices = [];

  @override
  Future<void> init() async {
	devices = await getFirmware();    
for (final device in devices) {
      await device.init();
	if (!device.isReady) continue;
      final subscription = device.stream?.listen((data) => _onMessage(data, device));
      if (subscription == null) continue;
      _subscriptions.add(subscription);
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    for (final device in devices) {
      await device.dispose();
    }
  }

  void _onMessage(Uint8List data, BurtFirmwareSerial serial) {
//	print("Received message from ${serial.device}: $data");
    final name = switch (serial.device) {
      Device.ARM => ArmData().messageName,
      Device.DRIVE => DriveData().messageName,
      Device.ELECTRICAL => ElectricalData().messageName,
      Device.GRIPPER => GripperData().messageName,
      Device.SCIENCE => ScienceData().messageName,
      _ => null,
    };
    if (name == null) {
      logger.warning("Unrecognized Serial device", body: "Port: ${serial.port}, name: ${serial.device}");
      return;
    }
	// TODO: Remove
/*
	if (name == DriveData().messageName) {
		try { 
			final data2 = DriveData.fromBuffer(data);
			print(data2.toProto3Json());
		} catch (error)  { }
	}
*/
    collection.server.sendWrapper(WrappedMessage(data: data, name: name));
  }

  @override
  bool sendWrapper(WrappedMessage wrapper) {
    final device = nameToDevice[wrapper.name];
    if (device == null) return false;
    final serial = devices.firstWhereOrNull((s) => s.device == device);
    if (serial == null) return false;
    serial.sendBytes(wrapper.data);
//	print("Sending ${wrapper.name} message: ${wrapper.data}");
//	logger.debug("Sent data over Serial: ${wrapper.name} --> $device");
    return true;
  }
}
