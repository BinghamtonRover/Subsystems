import "package:subsystems/subsystems.dart";
import "package:burt_network/burt_network.dart";

void main() async {
  Logger.level = LogLevel.debug;
  await collection.init();
}
