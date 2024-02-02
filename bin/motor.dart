import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

const speed = [0, 0, 0x9, 0xc4];

void main() async {
  Logger.level = LogLevel.info;
  await collection.init();
  while (true) {
    collection.can.can.sendMessage(id: 0x304, data: speed);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
