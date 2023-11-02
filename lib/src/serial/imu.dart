import "dart:convert";

import 'package:osc/osc.dart';
import "dart:typed_data";
import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

const port = "/dev/ttyACM0";

class ImuReader {
	final String port;

	ImuReader(this.port);

	void printXYZ(List <int> data){

		data = data.sublist(20);
		String message = utf8.decode(data, allowMalformed: true);

		logger.info("Received: $data");

		print("Message: ${message}");
		
		try {

		final message = OSCMessage.fromBytes(data);
		print (message);

		} catch (error) {

		print("Invalid message. Got error: $error");

		}
	}

	void init() {
		final Stream<List<int>> inputStream;
		ImuReader(this.inputStream);

		void intit() {
			inputStream.listen(printXYZ);
		}
	}
	void dispose() {
		ImuReader.dispose();
		logger.info("ImuReader disposed");

	}
}
