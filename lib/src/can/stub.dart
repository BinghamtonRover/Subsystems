import "dart:ffi";

import "package:burt_network/logging.dart";
import "ffi.dart";

/// An implementation of the CAN interface that does nothing, for platforms that don't support it.
class CanStub implements Can {
	/// Creates a mock CAN interface that does nothing and receives no messages.
	CanStub() {
		logger.warning("Using a mock CAN service");
	}

	@override
	void dispose() { }

	@override
	void sendMessage(Pointer<CanMessage> message) {	}

	@override
	Stream<CanMessage> get incomingMessages => const Stream<CanMessage>.empty();
}
