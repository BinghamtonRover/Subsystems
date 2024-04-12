import "dart:typed_data";

import "package:subsystems/subsystems.dart";

class FailingSerialPort extends SerialPortInterface {
  FailingSerialPort(super.portName);

  @override bool get isOpen => false;
  @override int get bytesAvailable => 0;

  @override bool openReadWrite() => throw UnsupportedError("Test port cannot open");
  @override Uint8List read(int count) => throw UnsupportedError("Test port cannot read");

  @override void dispose() { }
  @override bool write(Uint8List bytes) => throw UnsupportedError("Test port cannot write");
}
