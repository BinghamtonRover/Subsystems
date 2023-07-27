import "dart:async";
import "dart:ffi";
import "dart:typed_data";
import "package:ffi/ffi.dart";

import "package:burt_network/logging.dart";

import "package:subsystems/src/generated/can_ffi_bindings.dart";
export "package:subsystems/src/generated/can_ffi_bindings.dart";

typedef CanHandler = void Function(CanMessage message);

final nativeLib = CanBindings(DynamicLibrary.open("src/can.so"));

class Can {
	static const readInterval = Duration(milliseconds: 100);
	final Pointer<BurtCan> _can = nativeLib.can_init();
	final CanHandler onMessage;
	Timer? _timer;

	Can({required this.onMessage});

	void init() {
		_timer = Timer.periodic(readInterval, _checkForMessages);
	}

	void dispose() {
		nativeLib.can_destroy(_can);
		_timer?.cancel();
	}

	void sendMessage(Pointer<CanMessage> message) {
		nativeLib.can_send(_can, message);
		calloc.free(message);
	}

	void _checkForMessages(_) {
		int count = 0;
		while (true) {
			final pointer = nativeLib.can_read(_can);
			if (pointer == nullptr) return;
			count++;
			if (count == 10) logger.warning("Processed over 10 CAN messages in one callback. Consider decreasing the CAN read interval.");
			onMessage(pointer.ref);
			nativeLib.can_message_free(pointer);
		}
	}
}

extension on List<int> {
	Pointer<Uint8> toNativeBuffer() {
		final buffer = calloc<Uint8>(length);
		for (int i = 0; i < length; i++) {
			buffer[i] = this[i];
		}
		return buffer;
	}
}

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

extension CanMessageUtils on CanMessage {
	Uint8List get data => buffer.asTypedList(length);
}
