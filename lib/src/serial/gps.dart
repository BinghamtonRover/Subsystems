import "dart:convert";
import "dart:io";

const testInput = r"$GNGGA,000957.00,4205.21462,N,07558.04134,W,1,10,1.00,298.7,M,-34.4,M,,*7C";
const serialPort = "/dev/cu.usbmodem14201";

class Coordinates {
    final double latitude;
    final double longitude;
    final double altitude;
    const Coordinates(this.latitude, this.longitude, this.altitude);

    @override
    String toString() => "Latitude: $latitude, Longitude: $longitude, Altitude: $altitude";
}

class GpsReader {
    Coordinates? coordinates;
    Coordinates? parseNmeaToDecimal(String nmeaSentence) {
        final parts = nmeaSentence.split(",");
        final tag = parts.first;
        if (tag.endsWith("GGA")) {
            return Coordinates(
                nmeaToDecimal(double.tryParse(parts[2]) ?? 0.0), 
                nmeaToDecimal(double.tryParse(parts[4]) ?? 0.0),
                double.tryParse(parts[9]) ?? 0.0,
            );
        } else if (tag.endsWith("RMC")) {
            return Coordinates(
                nmeaToDecimal(double.tryParse(parts[3]) ?? 0.0), 
                nmeaToDecimal(double.tryParse(parts[5]) ?? 0.0),
                double.tryParse(parts[9]) ?? 0.0,
            );
        } else {
            return null;
        }
    }
    double nmeaToDecimal(double nmeaValue) {
        final degrees = nmeaValue ~/ 100;
        final minutes = nmeaValue % 100;
        return degrees + minutes / 60.0;
    }

    Future <void> init(List<String> args) async {
        if (args.contains("-t") || args.contains("--test")) {
            this.coordinates = parseNmeaToDecimal(testInput);
            print(coordinates); 
        } else {
            final process = await Process.start("cat", [serialPort]);
            process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
            this.coordinates = parseNmeaToDecimal(line);
            if (coordinates != null) print(coordinates);  
            });
        }
    }
}

void main(List<String> args) {
  final reader = GpsReader();
  reader.init(args);
}