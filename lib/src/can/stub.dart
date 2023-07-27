import "dart:ffi";

import "package:burt_network/logging.dart";
import "ffi.dart";

class CanStub implements Can {
	@override
	void init() {
		logger.info("Using a mock CAN service");
	}

	@override
	void dispose() { }

	@override
	void sendMessage(Pointer<CanMessage> message) {
		logger.warning("Sending a message to the mock CAN service:\n  ID: ${message.ref.id}, Data: ${message.ref.data}");
	}

	@override
	CanHandler get onMessage => noop;
}

void noop(_) { }
