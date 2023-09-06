import "dart:ffi";
import "package:subsystems/src/generated/can_ffi_bindings.dart";

export "dart:ffi";
export "package:ffi/ffi.dart";
export "package:subsystems/src/generated/can_ffi_bindings.dart";

/// The native SocketCAN-based library.
/// 
/// See `src/can.h` in this repository. Only supported on Linux.
final nativeLib = CanBindings(DynamicLibrary.open("src/burt_can/burt_can.so"));

/// These values come from the [BurtCanStatus] enum.
String? getCanError(int value) => switch(value) {
  1 => null,
  2 => "Could not create socket",
  3 => "Could not parse interface",
  4 => "Could not bind to socket",
  5 => "Could not close socket",
  6 => "Invalid MTU",
  7 => "CAN FD is not supported",
  8 => "Could not switch to CAN FD",
  9 => "Could not write data",
  10 => "Could not read data",
  _ => throw ArgumentError.value(value, "CanStatus", "Unknown CAN status"),
};
