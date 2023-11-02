/// Uses Dart's FFI to interop with native C code to use Linux's SocketCan.
/// 
/// - See [CanSocket] for usage. 
/// - See [this page](https://bing-rover.gitbook.io/software-docs/overview/network#firmware-to-onboard-computers-can-bus) for a broad overview of CAN.
/// - See [this page](https://bing-rover.gitbook.io/software-docs/network-details/can-bus) for an in-depth look into how we use CAN on the rover.
/// - See also: the [Wikipedia](https://en.wikipedia.org/wiki/CAN_bus) page for CAN bus.
library;

import "dart:async";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:subsystems/subsystems.dart";

import "src/can/message.dart";
import "src/can/socket_interface.dart";

export "src/can/message.dart";
export "src/can/socket_interface.dart";

/// Maps CAN IDs to [WrappedMessage.name] for data messages.
const Map<int, String> dataCanIDs = {1234: "ScienceData"};

///?
const Map<int, String> commandUdpIDs = {4567: "RoverPosition"} 

/// Maps [WrappedMessage.name] to CAN IDs for command messages.
const Map<String, int> commandCanIDs = {"ScienceCommand": 0x1234};

/// Manages a CAN socket on the subsystems program.
/// 
/// When a new message is received, its ID is looked up in [dataCanIDs] and sent over UDP.
/// When a UDP message is received, its ID is looked up in [commandCanIDs] and sent over CAN.
class CanService {
	/// The native CAN library. On non-Linux platforms, this will be a stub that does nothing.
	final can = CanSocket();

	late final StreamSubscription<CanMessage> _subscription;

	/// Initializes the CAN library.
	void init() {
		can.init();
		_subscription = can.incomingMessages.listen(onMessage);
	}

	/// Disposes the native CAN library and any resources it holds.
	void dispose() {
		_subscription.cancel();
		can.dispose();
	}

	/// Handles an incoming CAN message.
	void onMessage(CanMessage message) {
		logger.debug("Received CAN message (${message.id.toRadixString(16)}): ${message.data}");
		final name = dataCanIDs[message.id];
		if (name == null) {
			logger.warning("Unknown CAN ID: ${message.id}");
			return; 
		}
		// We must copy the data since we'll be disposing the pointer.
		final copy = List<int>.from(message.data);
		final wrapper = WrappedMessage(name: name, data: copy);
		collection.server.sendWrapper(wrapper);
		message.dispose();
	}

	/// Sends a [WrappedMessage] to the appropriate subsystem, using [commandCanIDs].
	void sendWrapper(WrappedMessage wrapper) {
		final id = commandCanIDs[wrapper.name];
		if (id == null) {
			logger.warning("Received unknown WrappedMessage: ${wrapper.name}");
			return;
		}
		can.sendMessage(id: id, data: wrapper.data);
	}
}
