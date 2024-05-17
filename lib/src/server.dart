import "dart:io";

import "package:burt_network/burt_network.dart";

import "package:subsystems/subsystems.dart";

/// A UDP server to connect to the dashboard.
/// 
/// This server should collect all commands that come in and forward them to the 
/// appropriate CAN device. All CAN messages should be forwarded to this server.
class SubsystemsServer extends RoverServer {
	/// Creates a Subsystems server on the given port.
	SubsystemsServer({required super.port}) : super(device: Device.SUBSYSTEMS);

	@override
	void onMessage(WrappedMessage wrapper) {
    if (wrapper.name == DriveData().messageName){
      final data = DriveData.fromBuffer(wrapper.data); 

      switch (data.status) {

        case RoverStatus.MANUAL:
          // send udp commands as normal
          collection.sendWrapper(wrapper);

        case RoverStatus.IDLE: 
          // ignore all udp commands
          break;

        case RoverStatus.POWER_OFF:
          if(Platform.isLinux){
            collection.stopHardware();
            // works the same as sudo shutdown now
            // Process.run("sudo poweroff", [""]); should also work? dart lsp was getting mad at me
            Process.run("sudo", ["poweroff"]);
          }
        
        case RoverStatus.RESTART:
          if(Platform.isLinux){
            collection.stopHardware();
            Process.run("sudo", ["reboot"]);
          }

        // case RoverStatus.DISCONNECTED:
        //   break;  

        // case RoverStatus.AUTONOMOUS:
        //   // potential autonomany shenanigans
        //   collection.sendWrapper(wrapper);
        //   break;
      }
    } 
	}

  @override
  Future<void> restart() async {
    await collection.dispose();
    await collection.init();
  }

  @override
  void onDisconnect() {
    super.onDisconnect();
    collection.stopHardware();
  }

  @override
  Future<void> onShutdown() => collection.dispose();
}
