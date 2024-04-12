import "dart:async";
import "dart:typed_data";

import "package:subsystems/subsystems.dart";

/// A wrapper around the `package:libserialport` library.
/// 
/// - Check [DelegateSerialPort.allPorts] for a list of all available ports.
/// - Call [init] to open the port
/// - Use [write] to write bytes to the port. Strings are not supported
/// - Listen to [stream] to get incoming data
/// - Call [dispose] to close the port
class SerialDevice extends Service {
  /// The port to connect to. 
	final String portName;
	/// How often to read from the port.
	final Duration readInterval;

	final SerialPortInterface _port;
  
	/// A timer to periodically read from the port (see [readBytes]).
	Timer? _timer;
  
	/// The controller for [stream].
	final _controller = StreamController<Uint8List>.broadcast();

	/// Manages a connection to a serial device.
	SerialDevice({
    required this.portName,
		required this.readInterval,
	}) : _port = SerialPortInterface.factory(portName);

	/// Whether the port is open (ie, the device is connected).
	bool get isOpen => _port.isOpen;

  @override
	Future<bool> init() async {
    try {
      return _port.openReadWrite();
    } catch (error) {
      return false;
    }
  }

  /// Starts listening to data sent over the serial port via [stream].
  void startListening() => _timer = Timer.periodic(readInterval, _listenForBytes);

  /// Stops listening to the serial port.
  void stopListening() => _timer?.cancel();

  /// Reads bytes from the port. If [count] is provided, only reads that number of bytes.
  Uint8List readBytes([int? count]) {
    try {
      return _port.read(count ?? _port.bytesAvailable);
    } catch (error) {
      logger.error("Could not read from serial port $portName:\n  $error");
      return Uint8List(0);
    }
  }

	/// Reads any data from the port and adds it to the [stream].
	void _listenForBytes(_) {
		try {
      final Uint8List bytes = readBytes();
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
		_port.dispose();
    await _controller.close();
	}

	/// Writes data to the port.
	void write(Uint8List data) {
    try { 
      _port.write(data);
    } catch (error) {
      // Ignore errors when writing
    }
  }

	/// All incoming bytes coming from the port.
	Stream<Uint8List> get stream => _controller.stream;
}
