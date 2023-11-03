import "package:subsystems/subsystems.dart";
import "package:burt_network/generated.dart";

void main() async {
  await collection.init();
  await Future<void>.delayed(Duration(seconds: 3));
  print("Sending a message");
  final wrapper = WrappedMessage(name: "ScienceCommand", data: ScienceCommand().writeToBuffer());
  collection.can.sendWrapper(wrapper);
  print("Done!");
}
