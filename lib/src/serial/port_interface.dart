import "dart:typed_data";

import "port_delegate.dart";
export "port_delegate.dart";

abstract class SerialPortInterface {
  static SerialPortInterface Function(String) factory = DelegateSerialPort.new;
  
  final String portName;
  SerialPortInterface(this.portName);
  
  bool get isOpen;
  int get bytesAvailable;
  
  bool openReadWrite();
  Uint8List read(int count);
  
  void dispose();
  void write(Uint8List bytes);
}
