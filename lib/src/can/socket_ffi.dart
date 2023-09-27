import "dart:async";

import "package:burt_network/logging.dart";

import "ffi.dart";
import "message.dart";
import "socket_interface.dart";

/// A function that handles a [CanMessage].
typedef CanHandler = void Function(CanMessage message);

/// The CAN interface to use.
const canInterface = "can0";
/// The CAN type to use -- CAN or CAN FD.
const canType = BurtCanType.CAN;
/// The timeout, in seconds, to wait for each message.
const canTimeout = 1;

/// The CAN interface, backed by the native SocketCAN library on Linux.
/// 
/// - Access [incomingMessages] to handle messages as they are received
/// - Call [sendMessage] to send a new [CanMessage]
/// - Be sure to call [dispose] when you're done to avoid memory leaks
/// 
/// Note that [CanMessage]s are natively allocated and need to be manually disposed of. Since this
/// class sends them through the [incomingMessages] stream, you are responsible for disposing them
/// if you listen to it. The stream gives you pointers so you can call [CanMessage.dispose].
class CanFFI implements CanSocket {
  /// How often to poll CAN messages.
  /// 
  /// This should be small enough to catch incoming messages but large enough to
  /// not block other code from runnng.
  static const readInterval = Duration(milliseconds: 100);

  /// The native CAN interface, as a C pointer.
  final Pointer<BurtCan> _can = nativeLib.BurtCan_create(canInterface.toNativeUtf8(), canTimeout, canType);

  /// Fills [incomingMessages] with new messages by calling [_checkForMessages].
  late final _controller = StreamController<CanMessage>(
    onListen: () => _startListening,
    onCancel: () => _stopListening,
    onPause: () => _stopListening,
    onResume: () => _startListening,
  );

  void _startListening() => _timer = Timer.periodic(readInterval, _checkForMessages);
  void _stopListening() => _timer?.cancel();

  @override
  Stream<CanMessage> get incomingMessages => _controller.stream;

  /// A timer to check for new messages.
  Timer? _timer;

  @override
  void init() { 
    final error = getCanError(nativeLib.BurtCan_open(_can));
    if (error != null) throw CanException(error);
    _startListening(); 
    
  }

  @override
  void dispose() {
    _stopListening();
    nativeLib.BurtCan_free(_can);
    _controller.close();
  }

  @override
  void sendMessage({required int id, required List<int> data}) {
    final message = CanMessage(id: id, data: data);
    nativeLib.BurtCan_send(_can, message.pointer);
    message.dispose();
  }

  /// Checks for new CAN messages and adds them to the [incomingMessages] stream.
  void _checkForMessages(_) {
    int count = 0;
    while (true) {
      final pointer = nativeLib.NativeCanMessage_create();
      nativeLib.BurtCan_receive(_can, pointer);
      if (pointer.ref.length == 0) return;
      count++;
      if (count == 10) logger.warning("Processed over 10 CAN messages in one callback. Consider decreasing the CAN read interval.");
      final message = CanMessage.fromPointer(pointer, isNative: true);
      _controller.add(message);
    }
  }
}