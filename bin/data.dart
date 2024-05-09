import "dart:math";

import "package:burt_network/burt_network.dart";
import "package:subsystems/subsystems.dart";

class SwingingIterator implements Iterator<double> {
  final double min;
  final double max;
  final double increment;
  SwingingIterator(this.min, this.max, this.increment) : current = min;

  bool forward = true;
  @override double current;

  @override
  bool moveNext() {
    if (current >= max && forward) forward = false;
    if (current <= min && !forward) forward = true;
    if (forward) {
      current += increment;
    } else {
      current -= increment;
    }
    return true;
  }
}

Future<void> main() async {
  final server = SubsystemsServer(port: 8001);
  await server.init();
  final throttle = SwingingIterator(0, 1, 0.01);
  final voltage = SwingingIterator(24, 30, 0.1);
  final current = SwingingIterator(0, 30, 0.1);
  final motor = SwingingIterator(0, pi, 0.01);
  final motor2 = SwingingIterator(0, 2*pi, 0.05);
  while (true) {
    // final x = ArmData(shoulder: MotorData(angle: pi), elbow: MotorData(angle: pi));
    // final y = GripperData(lift: MotorData(angle: pi));
    // server.sendMessage(x);
    // server.sendMessage(y);
    // await Future<void>.delayed(const Duration(milliseconds: 100));
    // continue;
    
    throttle.moveNext();
    voltage.moveNext();
    current.moveNext();
    motor.moveNext();
    motor2.moveNext();
    final data = DriveData(left: 1, setLeft: true, right: -1, setRight: true, throttle: throttle.current, setThrottle: true, batteryVoltage: voltage.current, batteryCurrent: current.current); 
    server.sendMessage(data);
    final data2 = ArmData(base: MotorData(angle: motor2.current), shoulder: MotorData(angle: motor.current), elbow: MotorData(angle: motor.current));
    server.sendMessage(data2);
    final data3 = GripperData(lift: MotorData(angle: motor.current));
    server.sendMessage(data3);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
