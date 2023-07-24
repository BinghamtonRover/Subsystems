import "package:burt_network/burt_network.dart";

import "collection.dart";

/// A CAN message, as defined by the CAN protocol.
/// 
/// See https://en.wikipedia.org/wiki/CAN_bus#Data_frame.
class CanMessage {
	/// The CAN ID of this message.
	final int id;
	/// The data contained in this message.
	final List<int> data;
	/// Creates a new CanMessage with the given id and data.
	const CanMessage({required this.id, required this.data});
}

/// Maps CAN IDs to [WrappedMessage.name] for data messages.
const Map<int, String> dataCanIDs = {};

/// Maps [WrappedMessage.name] to CAN IDs for command messages.
const Map<String, int> commandCanIDs = {};

/// Manages a CAN socket on the subsystems program.
/// 
/// When a new message is received, its ID is looked up in [dataCanIDs] and sent over UDP.
/// When a UDP message is received, its ID is looked up in [commandCanIDs] and sent over CAN.
class Can extends CanSocket {
	@override
	void onData(CanMessage message) {
		logger.debug("Received CAN message (${message.id.toRadixString(16)}): ${message.data}");
		final name = dataCanIDs[message.id];
		if (name == null) {
			logger.warning("Unknown CAN ID: ${message.id}");
			return; 
		}
		final wrapper = WrappedMessage(name: name, data: message.data);
		collection.server.sendWrapper(wrapper);
	}

	/// Sends a [WrappedMessage] to the appropriate subsystem, using [commandCanIDs].
	void sendMessage(WrappedMessage wrapper) {
		final id = commandCanIDs[wrapper.name];
		if (id == null) {
			logger.warning("Received unknown WrappedMessage: ${wrapper.name}");
			return;
		}
		final canMessage = CanMessage(id: id, data: wrapper.data);
		sendData(canMessage);
	}
}

// ----------------- Ignore everything below this line -----------------

/// A socket to send and receive messages over CAN.
/// 
/// See https://en.wikipedia.org/wiki/CAN_bus.
abstract class CanSocket {
	/// Open the socket.
	Future<void> init() async { }
	/// Close the socket.
	Future<void> dispose() async { }

	/// Override this function to handle incoming CAN messages.
	void onData(CanMessage message);

	/// Send data over CAN.
	void sendData(CanMessage message) { }
}
