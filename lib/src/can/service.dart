import "dart:io";
import "dart:ffi";
import "package:burt_network/burt_network.dart";

import "package:subsystems/subsystems.dart";
import "ffi.dart";
import "stub.dart";

/// Maps CAN IDs to [WrappedMessage.name] for data messages.
const Map<int, String> dataCanIDs = {1234: "ScienceData"};

/// Maps [WrappedMessage.name] to CAN IDs for command messages.
const Map<String, int> commandCanIDs = {"ScienceCommand": 0x1234};

/// Manages a CAN socket on the subsystems program.
/// 
/// When a new message is received, its ID is looked up in [dataCanIDs] and sent over UDP.
/// When a UDP message is received, its ID is looked up in [commandCanIDs] and sent over CAN.
class CanService {
	late final can = Platform.isLinux ? Can(onMessage: onMessage) : CanStub();

	void init() => can.init();
	void dispose() => can.dispose();

	void onMessage(CanMessage message) {
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
	void sendWrapper(WrappedMessage wrapper) {
		final id = commandCanIDs[wrapper.name];
		if (id == null) {
			logger.warning("Received unknown WrappedMessage: ${wrapper.name}");
			return;
		}
		final Pointer<CanMessage> canMessage = createCanMessage(id: id, data: wrapper.data);
		can.sendMessage(canMessage);
	}
}
