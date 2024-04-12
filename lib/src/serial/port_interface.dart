import "dart:typed_data";

import "port_delegate.dart";
export "port_delegate.dart";

/// An interface to a serial port.
abstract class SerialPortInterface {
  /// The default kind of port to create. Use this when mocking with different ports.
  static SerialPortInterface Function(String) factory = DelegateSerialPort.new;
  
  /// The name of the port.
  final String portName;
  
  /// Creates a serial port at the given name.
  SerialPortInterface(this.portName);
  
  /// Whether this port is open.
  bool get isOpen;
  
  /// How many bytes are available to be read.
  int get bytesAvailable;
  
  /// Opens the port for reading and writing.
  bool openReadWrite();
  
  /// Reads the given number of bytes from the port.
  Uint8List read(int count);
  
  /// Writes data to the port.
  void write(Uint8List bytes);

  /// Closes the port and releases its resources. The port may be used again.
  void dispose();
}
