import "dart:async";
import "dart:typed_data";

import "package:subsystems/subsystems.dart";

import "port_interface.dart";

/// A wrapper around the `package:libserialport` library.
/// 
/// - Check [allPorts] for a list of all available ports.
/// - Call [init] to open the port
/// - Use [write] to write bytes to the port. Strings are not supported
/// - Listen to [stream] to get incoming data
/// - Call [dispose] to close the port
class SerialDevice extends Service {
	/// The port to connect to.
	final String portName;
	/// How often to read from the port.
	final Duration readInterval;

	SerialInterface? _port;
  
	/// A timer to periodically read from the port (see [readBytes]).
	Timer? _timer;
  
	/// The controller for [stream].
	final _controller = StreamController<Uint8List>.broadcast();

	/// Manages a connection to a serial device. See [allPorts].
	SerialDevice({
		required this.portName,
		required this.readInterval,
	});

	/// Whether the port is open (ie, the device is connected).
	bool get isOpen => _port?.isOpen ?? false;

  @override
	Future<bool> init() async {
		_port = DelegateSerialPort(portName);
    return _port!.openReadWrite();
	}

  /// Starts listening to data sent over the serial port via [stream].
  void startListening() => _timer = Timer.periodic(readInterval, _listenForBytes);

  /// Stops listening to the serial port.
  void stopListening() => _timer?.cancel();

  /// Reads bytes from the port. If [count] is provided, only reads that number of bytes.
  Uint8List readBytes({int? count}) => _port!.read(count ?? _port!.bytesAvailable);

	/// Reads any data from the port and adds it to the [stream].
	void _listenForBytes(_) {
		try {
      final Uint8List bytes = _port!.read(_port!.bytesAvailable);
      if (bytes.isEmpty) return;
      _controller.add(bytes);
		} catch (error) {
      logger.critical("Could not read $portName", body: error.toString());
      dispose();
		}
	}

  @override
	Future<void> dispose() async {
    _timer?.cancel();
		_port?.dispose();
    _port = null;
	}

	/// Writes data to the port.
	void write(Uint8List data) {
    if (_port == null) {
      logger.error("Could not send to $portName", body: "Port is not opened");
    } else {
      _port?.write(data);
    }
  }

	/// All incoming bytes coming from the port.
	Stream<Uint8List> get stream => _controller.stream;
}
