import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

void main() async {
  Logger.level = LogLevel.trace;
  await collection.init();
}
