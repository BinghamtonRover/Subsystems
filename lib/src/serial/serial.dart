import "dart:async";
import "dart:typed_data";
import "package:libserialport/libserialport.dart";

import "package:subsystems/subsystems.dart";

/// A wrapper around the `package:libserialport` library.
/// 
/// - Check [allPorts] for a list of all available ports.
/// - Call [open] to open the port
/// - Use [write] to write bytes to the port. Strings are not supported
/// - Listen to [stream] to get incoming data
/// - Call [dispose] to close the port
/// 
/// The device can no longer be used after calling [dispose]. Create a new one with
/// the same port name and call [open] again.
class SerialDevice {
	/// A list of all available ports on the device.
	static List<String> allPorts = SerialPort.availablePorts;

	/// The port to connect to.
	final String portName;
	/// How often to read from the port.
	final Duration readInterval;

	/// The `package:libserialport` port object for reading and writing.
	SerialPort? _port;
	/// A timer to periodically read from the port (see [_readBytes]).
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

	/// Opens the port and begins reading from it.
	void open() {
		_port = SerialPort(portName);
		if (!_port!.openReadWrite()) {
			throw SerialPortUnavailable(portName);
		}
		_timer = Timer.periodic(readInterval, _readBytes);
	}

	/// Reads any data from the port and adds it to the [stream].
	void _readBytes(_) {
		try {
      final Uint8List bytes = _port!.read(_port!.bytesAvailable);
      if (bytes.isEmpty) return;
      _controller.add(bytes);
		} catch (error) {
      logger.critical("Could not read $portName", body: error.toString());
      dispose();
		}
	}

	/// Closes the port and frees any allocated resources associated with it.
	/// 
	/// This port cannot be re-opened. You must use a new [SerialDevice] and call [open] on that.
	void dispose() {
		_timer?.cancel();
		_port?.close();
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

	/// Reads data from the port.
	Stream<Uint8List> get stream => _controller.stream;
}

/// An error that is thrown when a serial port cannot be opened.
/// 
/// Use a port from [SerialDevice.allPorts] to avoid this error.
class SerialPortUnavailable implements Exception {
	/// The port that did not open.
	final String port;
	/// A const constructor.
	const SerialPortUnavailable(this.port);

	@override
	String toString() => "Could not open serial port $port";
}

/// Indicates that some unknown error occurred while reading a serial port.
class SerialReadException implements Exception { 
	/// The port that caused the error.
	final String port;
	/// The error that occurred.
	final Object? error;
	/// A const constructor.
	const SerialReadException({required this.port, required this.error});

	@override
	String toString() => "Error reading from port $port: $error";
}
