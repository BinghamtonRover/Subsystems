import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

void main() async {
  BurtLogger.level = LogLevel.debug;  
  await collection.init();
}
