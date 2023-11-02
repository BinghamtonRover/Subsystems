import "dart:convert";
import "dart:io";
import "package:burt_network/burt_network.dart";
import "package:subsystems/can.dart";
import "package:protobuf/gps.proto";
import "package:subsystems/subsytems.dart";

const testInput = r"$GNGGA,000957.00,4205.21462,N,07558.04134,W,1,10,1.00,298.7,M,-34.4,M,,*7C";
const serialPort = "/dev/cu.usbmodem14201";

class GpsReader {
    Coordinates? coordinates;
    Coordinates? _parseNmeaToDecimal(String nmeaSentence) {
        final parts = nmeaSentence.split(",");
        final tag = parts.first;
        if (tag.endsWith("GGA")) {
            return Coordinates(
                x: _nmeaToDecimal(double.tryParse(parts[2]) ?? 0.0), 
                y: _nmeaToDecimal(double.tryParse(parts[4]) ?? 0.0),
                z: double.tryParse(parts[9]) ?? 0.0,
            );
        } else if (tag.endsWith("RMC")) {
            return Coordinates(
                x: _nmeaToDecimal(double.tryParse(parts[3]) ?? 0.0), 
                y: _nmeaToDecimal(double.tryParse(parts[5]) ?? 0.0),
                z: double.tryParse(parts[9]) ?? 0.0,
            );
        } else {
            return null;
        }
    }
    double _nmeaToDecimal(double nmeaValue) {
        final degrees = nmeaValue ~/ 100;
        final minutes = nmeaValue % 100;
        return degrees + minutes / 60.0;
    }

    final CanService can = CanService();

    Future <void> init(List<String> args) async {

        can.init();

        if (args.contains("-t") || args.contains("--test")) {
            coordinates = _parseNmeaToDecimal(testInput);

            _sendToDashboard(coordinates);

            print(coordinates); 
        } else {
            final process = await Process.start("cat", [serialPort]);
            process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
                coordinates = _parseNmeaToDecimal(line);
                if (coordinates != null) {
                    _sendToDashboard(coordinates);
                    
                } 
            });
        }
    }

    void _sendToDashboard(Coordinates? coords) {
    if (coords == null) return;

    var roverPosition = RoverPosition();
    var gpsCoordinates = GpsCoordinates();
    gpsCoordinates.latitude = coords.latitude;
    gpsCoordinates.longitude = coords.longitude;
    gpsCoordinates.altitude = coords.altitude;

    // Protobuf nesnesini byte array'e dönüştür
    List<int> bytes = roverPosition.writeToBuffer();

    // sendWrapper fonksiyonu ile gönder
    collection.server.sendMessage(roverPosition);
    }
}

void main(List<String> arguments) async {
    GpsReader gps = GpsReader();
    await gps.init(arguments);
}