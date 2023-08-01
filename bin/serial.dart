// ignore_for_file: avoid_print
import "dart:typed_data";
import "package:subsystems/subsystems.dart";

void main() async {
	final device = SerialDevice(
		portName: "COM11", 
		readInterval: const Duration(seconds: 1),
	);
	device.open();
	device.stream.listen(print);
	device.write(Uint8List.fromList([1, 2, 3]));
}
