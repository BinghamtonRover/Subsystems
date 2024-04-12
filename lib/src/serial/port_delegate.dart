import "dart:typed_data";

import "package:libserialport/libserialport.dart";

import "port_interface.dart";

/// A serial port implementation that delegates to [`package:libserialport`](https://pub.dev/packages/libserialport)
class DelegateSerialPort extends SerialPortInterface {
	/// A list of all available ports on the device.
	static List<String> allPorts = SerialPort.availablePorts;
  
  SerialPort _delegate;

  /// Creates a serial port that delegates to the `libserialport` package.
  DelegateSerialPort(super.portName) : 
    _delegate = SerialPort(portName);

  @override
  bool get isOpen => _delegate.isOpen;
  
  @override
  bool openReadWrite() => _delegate.openReadWrite();
  
  @override
  int get bytesAvailable => _delegate.bytesAvailable;
  
  @override
  Uint8List read(int count) => _delegate.read(count);
  
  @override
  void write(Uint8List bytes) => _delegate.write(bytes);
  
  @override
  void dispose() {
    _delegate.close();
    _delegate.dispose();
    _delegate = SerialPort(portName);
  }
}
