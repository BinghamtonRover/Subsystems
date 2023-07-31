/// Uses Dart's FFI to interop with native C code to use Linux's SocketCan.
/// 
/// - See [CanSocket] for usage. 
/// - See [this page](https://bing-rover.gitbook.io/software-docs/overview/network#firmware-to-onboard-computers-can-bus) for a broad overview of CAN.
/// - See [this page](https://bing-rover.gitbook.io/software-docs/network-details/can-bus) for an in-depth look into how we use CAN on the rover.
/// - See also: the [Wikipedia](https://en.wikipedia.org/wiki/CAN_bus) page for CAN bus.
library;

import "src/can/interface.dart";

export "src/can/interface.dart";
export "src/can/message.dart";
export "src/can/service.dart";
export "src/can/socket.dart";
export "src/can/stub.dart";
