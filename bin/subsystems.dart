import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

void main() async {
  Logger.level = LogLevel.info;
  await collection.init();
}
