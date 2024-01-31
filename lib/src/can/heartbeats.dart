import "dart:async";

import "package:meta/meta.dart";
import "package:burt_network/generated.dart";
import "package:subsystems/can.dart";

const firmwareDevices = [Device.DRIVE, Device.ARM, Device.GRIPPER, Device.SCIENCE];
const heartbeatSendInterval = Duration(milliseconds: 100);
const heartbeatCheckInterval = Duration(milliseconds: 500);
const heartbeatSendID = 1;
final heartbeat = List.filled(8, 42);
const heartbeatIDs = <int, Device>{
  2: Device.DRIVE,
  3: Device.ARM,
  4: Device.GRIPPER,
  5: Device.SCIENCE,
};

mixin SendCanHeartbeats {
  CanSocket get can;
  
  Timer? _heartbeatSendTimer;
  Timer? _heartbeatCheckTimer;
  StreamSubscription<CanMessage>? _subscription;
  late Map<Device, bool> _hasHeartbeats;
  late Map<Device, bool> _hasBeenNotified;

  @mustCallSuper
  Future<void> init() async {
    _heartbeatSendTimer = Timer.periodic(heartbeatSendInterval, (_) => _sendHeartbeat());
    _heartbeatCheckTimer = Timer.periodic(heartbeatCheckInterval, (_) => _checkHeartbeats());
    _subscription = can.incomingMessages.listen(_onMessage);
    _hasHeartbeats = {
      for (final device in firmwareDevices)
        device: false,
    };
    _hasBeenNotified = {
      for (final device in firmwareDevices)
        device: false,
    };
  }

  @mustCallSuper
  Future<void> dispose() async {
    _heartbeatSendTimer?.cancel();
    _heartbeatCheckTimer?.cancel();
    await _subscription?.cancel();
  }

  void _sendHeartbeat() { 
    can.sendMessage(id: heartbeatSendID, data: heartbeat);
  }

  void _checkHeartbeats() {
    for (final device in firmwareDevices) {
      if (!_hasHeartbeats[device]! && !_hasBeenNotified[device]!) {
        onDisconnect(device);
        _hasBeenNotified[device] = true;
      }
      _hasHeartbeats[device] = false;
    }
  }

  void _onMessage(CanMessage message) {
    final device = heartbeatIDs[message.id];
    if (device == null) return;
    _hasHeartbeats[device] = true;
  }

  void onDisconnect(Device device);  
}
