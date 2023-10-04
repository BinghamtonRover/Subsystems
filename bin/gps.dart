import "dart:convert";
import "dart:io";

typedef DMS = ({int degrees, int minutes, double seconds});

const testInput = r"$GNGGA,000957.00,4205.21462,N,07558.04134,W,1,10,1.00,298.7,M,-34.4,M,,*7C";
const serialPort = "/dev/cu.usbmodem14201";

class TPVSentence {
  static DMS tpvToDms(double tpv) {
    // 12045.25 --> 120 deg, 45 min, 15 sec
    final degrees = tpv ~/ 100;  // eg, 120
    final decimalMinutes = tpv % 100;  // eg, 45.25
    final minutes = decimalMinutes.toInt();  // eg, 45
    final seconds = (decimalMinutes - minutes) * 60;  // eg, 0.25 * 60 = 15
    return (degrees: degrees, minutes: minutes, seconds: seconds);
  }

  final DMS latitude;
  final DMS longitude;
  final double altitude;

  TPVSentence({
    required this.latitude, 
    required this.longitude, 
    required this.altitude,
  });

  @override
  String toString() => "Latitude: $latitude, Longitude: $longitude, Altitude: $altitude";
}

TPVSentence? parseTpv(String nmeaSentence) {
  final parts = nmeaSentence.split(",");
  final tag = parts.first;
  if (tag.endsWith("GGA")) {
    return TPVSentence(
      latitude: TPVSentence.tpvToDms(double.tryParse(parts[2]) ?? 0.0), 
      longitude: TPVSentence.tpvToDms(double.tryParse(parts[4]) ?? 0.0),
      altitude: double.tryParse(parts[9]) ?? 0.0,
    );

  } else if (tag.endsWith("RMC")) {
    return TPVSentence(
      latitude: TPVSentence.tpvToDms(double.tryParse(parts[3]) ?? 0.0), 
      longitude: TPVSentence.tpvToDms(double.tryParse(parts[5]) ?? 0.0),
      altitude: double.tryParse(parts[9]) ?? 0.0,
    );
  } else {
    return null;
  }
}

void main(List<String> args) async {
  if (args.contains("-t") || args.contains("--test")) {
    final tpv = parseTpv(testInput);
    print(tpv);  // ignore: avoid_print
  } else {
    final process = await Process.start("cat", [serialPort]);
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      final tpv = parseTpv(line);
      if (tpv != null) print(tpv);  // ignore: avoid_print
    });
  }
}
