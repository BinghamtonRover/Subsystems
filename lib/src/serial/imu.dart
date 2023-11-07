import "dart:convert";

import "package:osc/osc.dart";
import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";

class ImuReader {
	final String port;
  final SerialDevice serial;
	ImuReader(this.port) : serial = SerialDevice(portName: port, readInterval: Duration(milliseconds: 500));

	void parseOsc(List <int> data) {
		try {
      final message = OSCMessage.fromBytes(data.sublist(20));
      logger.info("Received: $message");		
		} catch (error) { 
      final rawLine = utf8.decode(data.sublist(20));
      logger.warning("Received $rawLine");
    }
	}

	void init() {
    serial.stream.listen(parseOsc);
	}

	void dispose() {
		logger.info("ImuReader disposed");
	}
}
