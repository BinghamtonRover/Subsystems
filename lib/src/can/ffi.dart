import "dart:async";
import "dart:ffi";
import "dart:typed_data";
import "package:ffi/ffi.dart";

import "package:burt_network/logging.dart";

import "package:subsystems/src/generated/can_ffi_bindings.dart";
export "package:subsystems/src/generated/can_ffi_bindings.dart";

import "stub.dart";

/// A function that handles a [CanMessage].
typedef CanHandler = void Function(CanMessage message);

/// The native SocketCAN-based library.
/// 
/// See `src/can.h` in this repository. Only supported on Linux.
final nativeLib = CanBindings(DynamicLibrary.open("src/can.so"));

/// The CAN interface, backed by the native SocketCAN library on Linux.
/// 
/// This class is only supported on Linux. On non-Linux platforms, use [CanStub] instead. 
/// 
/// - Access [incomingMessages] to handle messages as they are received
/// - Call [sendMessage] to send a new [CanMessage]. Create one using [createCanMessage]
/// - Be sure to call [dispose] when you're done to avoid memory leaks
class Can {
	/// How often to poll CAN messages.
	/// 
	/// This should be small enough to catch incoming messages but large enough to
	/// not block other code from runnng.
	static const readInterval = Duration(milliseconds: 100);

	/// The native CAN interface, as a C pointer.
	final Pointer<BurtCan> _can = nativeLib.can_init();

	late final StreamController<CanMessage> _controller = StreamController<CanMessage>(
		onListen: _startListening,
		onCancel: _stopListening,
		onPause: _stopListening,
		onResume: _startListening,
	);

	/// A stream of incoming CAN messages. Use [Stream.listen] to handle them.
	/// 
	/// This stream is a single-subscription stream, which means only one receiver is allowed,
	/// and the stream does not check for new events until a listener is added.
	Stream<CanMessage> get incomingMessages => _controller.stream;

	/// A timer to check for new messages.
	Timer? _timer;

	/// Disposes of native resources allocated to this object, and stops listening for CAN messages.
	void dispose() {
		nativeLib.can_destroy(_can);
		_timer?.cancel();
		_controller.close();
	}

	void _startListening() {
		_timer = Timer.periodic(readInterval, _checkForMessages);
	}

	void _stopListening() {
		_timer?.cancel();
		_timer = null;
	}

	/// Sends a CAN message and disposes of it immediately. Do not use it after this is called.
	void sendMessage(Pointer<CanMessage> message) {
		nativeLib.can_send(_can, message);
		calloc.free(message.ref.buffer);
		calloc.free(message);
	}

	/// Checks for new CAN messages and adds them to the [incomingMessages] stream.
	void _checkForMessages(_) {
		int count = 0;
		while (true) {
			final pointer = nativeLib.can_read(_can);
			if (pointer == nullptr) return;
			count++;
			if (count == 10) logger.warning("Processed over 10 CAN messages in one callback. Consider decreasing the CAN read interval.");
			_controller.add(pointer.ref);
			nativeLib.can_message_free(pointer);
		}
	}
}

extension on List<int> {
	/// Copies a list of bytes in Dart into a newly-allocated`char*`, which must be freed.
	Pointer<Uint8> toNativeBuffer() {
		final buffer = calloc<Uint8>(length);
		for (int i = 0; i < length; i++) {
			buffer[i] = this[i];
		}
		return buffer;
	}
}

/// Allocates a new [CanMessage] in native memory.
/// 
/// This must be freed after use. For example, [Can.sendMessage] frees this after sending it.
Pointer<CanMessage> createCanMessage({
	required int id,
	required List<int> data,
}) {
	final pointer = calloc<CanMessage>();
	pointer.ref.id = id;
	pointer.ref.buffer = data.toNativeBuffer();
	pointer.ref.length = data.length;
	return pointer;
}

/// Extension methods on [CanMessage]s.
extension CanMessageUtils on CanMessage {
	/// Allows you to access a native `char*` as a [Uint8List].
	Uint8List get data => buffer.asTypedList(length);
}
