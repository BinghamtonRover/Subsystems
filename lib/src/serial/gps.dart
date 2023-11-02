import "dart:convert";
import "dart:io";

import "package:burt_network/burt_network.dart";
import "package:subsystems/subsystems.dart";

const testInput = r"$GNGGA,000957.00,4205.21462,N,07558.04134,W,1,10,1.00,298.7,M,-34.4,M,,*7C";
const serialPort = "/dev/ttyACM0";
final testCoordinates = GpsCoordinates();

class GpsReader {
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
        altitude: double.tryParse(parts[9]) ?? 0.0,
      );
    }
  }

  static double _nmeaToDecimal(double nmeaValue) {
    final degrees = nmeaValue ~/ 100;
    final minutes = nmeaValue % 100;
    return degrees + minutes / 60.0;
  }

  Process? cat;
  final bool verbose;
  GpsReader({this.verbose = false});

  void handleLine(String line) {
    final coordinates = parseNMEA(line);
    if (coordinates == null) return;
    if (verbose) logger.debug("GPS Read: $coordinates");
    final roverPosition = RoverPosition(gps: coordinates);
    collection.server.sendMessage(roverPosition);
  }

  Future<void> init() async {
    cat = await Process.start("cat", [serialPort]);
    cat!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(handleLine);
  }

  void dispose() => cat?.terminate();

  void _sendToDashboard(GpsCoordinates? coordinates) {
    if (coordinates == null) return;
    // print("Sending to dashboard: $coordinates");
  }
}
