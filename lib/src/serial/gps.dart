import "dart:convert";
import "dart:io";

import "package:burt_network/burt_network.dart";
import "package:subsystems/subsystems.dart";

/// The port/device file to listen to the GPS on.
const serialPort = "/dev/rover-gps";

/// Listens to the GPS and sends its output to the Dashboard. 
/// 
/// Call [init] to start listening and [dispose] to stop.
class GpsReader {
  /// Parses an NMEA sentence into a [GpsCoordinates] object.
  /// 
  /// See https://shadyelectronics.com/gps-nmea-sentence-structure.
  static GpsCoordinates? parseNMEA(String nmeaSentence) {
    final parts = nmeaSentence.split(",");
    final tag = parts.first;
    if (tag.endsWith("GGA")) {
      return GpsCoordinates(
        latitude: _nmeaToDecimal(double.tryParse(parts[2]) ?? 0.0), 
        longitude: _nmeaToDecimal(double.tryParse(parts[4]) ?? 0.0),
        altitude: double.tryParse(parts[9]) ?? 0.0,
      );
    } else if (tag.endsWith("RMC")) {
      return GpsCoordinates(
        latitude: _nmeaToDecimal(double.tryParse(parts[3]) ?? 0.0), 
        longitude: _nmeaToDecimal(double.tryParse(parts[5]) ?? 0.0),
      );
    } else if (tag.endsWith("GLL")) {
      return GpsCoordinates(
        latitude: _nmeaToDecimal(double.tryParse(parts[1]) ?? 0.0),
        longitude: _nmeaToDecimal(double.tryParse(parts[3]) ?? 0.0),
      );
    } else {
      return null;
    }
  }

  static double _nmeaToDecimal(double nmeaValue) {
    final degrees = nmeaValue ~/ 100;
    final minutes = nmeaValue % 100;
    return degrees + minutes / 60.0;
  }

  /// The `cat` process that's reading from the GPS.
  Process? cat;

  /// Parses a line of NMEA output and sends the GPS coordinates to the dashboard.
  void handleLine(String line) {
    final coordinates = parseNMEA(line);
    if (coordinates == null) return;
    final roverPosition = RoverPosition(gps: coordinates);
    collection.server.sendMessage(roverPosition);
  }

  /// Starts reading the GPS (on [serialPort]) through the `cat` Linux program.
  Future<void> init() async {
    logger.info("Reading GPS on port $serialPort");
    cat = await Process.start("cat", [serialPort]);
    cat!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(handleLine);
  }

  /// Closes the [cat] process to stop listening to the GPS.
  void dispose() => cat?.kill();
}
