import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

const speed = [0, 0, 0x10, 0];

void main() async {
  BurtLogger.level = LogLevel.info;  
  await collection.init();
  while (true) {
    collection.can.can.sendMessage(id: 0x303, data: speed);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
