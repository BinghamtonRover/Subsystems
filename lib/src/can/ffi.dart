import "dart:ffi";

import "package:subsystems/src/generated/can_ffi_bindings.dart";
export "package:subsystems/src/generated/can_ffi_bindings.dart";

/// The native SocketCAN-based library.
/// 
/// See `src/can.h` in this repository. Only supported on Linux.
final nativeLib = CanBindings(DynamicLibrary.open("src/burt_can/burt_can.so"));
