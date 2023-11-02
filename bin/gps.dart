import "package:subsystems/subsystems.dart";

void main() async {
  final reader = GpsReader(verbose: true);
  await reader.init();
}
