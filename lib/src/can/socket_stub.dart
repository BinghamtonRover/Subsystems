import "package:burt_network/logging.dart";

import "message.dart";
import "socket_interface.dart";

/// An implementation of the CAN interface that does nothing for platforms that don't support it.
class CanStub implements CanSocket {
	/// Creates a mock CAN interface that does nothing and receives no messages.
	CanStub() {
		logger.warning("Using a mock CAN service");
	}

	@override
	void init() { }

	@override
	void dispose() { }

	@override
	void sendMessage({required int id, required List<int> data}) {	}

	@override
	Stream<CanMessage> get incomingMessages => const Stream<CanMessage>.empty();
}
