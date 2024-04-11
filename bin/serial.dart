import "dart:typed_data";
import "package:subsystems/subsystems.dart";
import "package:burt_network/logging.dart";
import "package:burt_network/generated.dart";
import "package:libserialport/libserialport.dart";

final logger = BurtLogger();

bool ascii = false;

void main(List<String> args) async {
	if (args.isEmpty) {
		logger.info("Ports: ${SerialPort.availablePorts}");
		return;
	} else if (args.contains("-h") || args.contains("--help")) {
		logger.info("Usage: dart run -r :serial [port] [-a | --ascii]");
		return;
	}
	var port = args.first;
	if (!port.startsWith("/dev")) port = "/dev/$port";
	if (args.contains("-a") || args.contains("--ascii")) {
		logger.info("Running in ASCII mode");
		ascii = true;
	}
	logger.info("Connecting to $port...");
	final device = SerialDevice(
		portName: port, 
		readInterval: const Duration(milliseconds: 100),
	);
	device.open();
	logger.info("Connected. Listening...");
	device.stream.listen(process);
	device.startListening();
}

void process(Uint8List buffer) {
	if (ascii) {
		final s = String.fromCharCodes(buffer).trim();
		logger.debug("Got string: $s");	
	} else {
		final data = DriveData.fromBuffer(buffer);
		logger.debug("Got data: ${data.toProto3Json()}");
	}
}
