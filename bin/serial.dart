import "dart:typed_data";
import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

const port = "COM11";

final logger = BurtLogger();

void main() async {
	final device = SerialDevice(
		portName: port, 
		readInterval: const Duration(milliseconds: 100),
	);
	device.open();
	device.stream.listen((data) => logger.info("Received: $data"));
	device.write(Uint8List.fromList([1, 2, 3]));
}
