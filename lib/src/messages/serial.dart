import "dart:async";
import "dart:typed_data";

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
  final List<StreamSubscription<Uint8List>> _subscriptions = [];
  final List<BurtFirmwareSerial> devices = [
    /* Fill in your devices and ports here, eg: */
    // BurtFirmwareSerial("/dev/ttyACM0"),
  ];

  @override
  Future<void> init() async {
    for (final device in devices) {
      await device.init();
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
    collection.server.sendWrapper(WrappedMessage(data: data, name: name));
  }

  @override
  void sendWrapper(WrappedMessage wrapper) {
    final device = nameToDevice[wrapper.name];
    if (device == null) return;
    final serial = devices.firstWhereOrNull((s) => s.device == device);
    if (serial == null) return;
    serial.sendBytes(wrapper.data);
  }
}
