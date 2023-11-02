import "dart:convert";

import 'package:osc/osc.dart';
import "dart:typed_data";
import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

const port = "/dev/ttyACM0";

// void printXYZ(List<int> data) {
// 	data = data.sublist(20);
// 	String message = utf8.decode(data, allowMalformed: true);
// 	logger.info("Received: $data");
// 	print("Message: ${message}");
// 	try {
// 		final message = OSCMessage.fromBytes(data);
// 		print (message);
// 	} catch (error) {
// 		print("Invalid message. Got error: $error");
// 	}
// }

// void main() async {
// 	final device = SerialDevice(
// 		portName: port, 
// 		readInterval: const Duration(milliseconds: 500),
// 	);
// 	device.open();
// 	device.stream.listen(printXYZ);
// 	// device.write(Uint8List.fromList([1, 2, 3]));
// }

void main() {
	reader = ImuReader(stdin);
	reader.init();
}
