import 'dart:convert';
import 'dart:io';

final input = "\$GNGGA,000957.00,4205.21462,N,07558.04134,W,1,10,1.00,298.7,M,-34.4,M,,*7C";

class TPV {
  final String type;
  final int mode;
  final double latitude;
  final double longitude;
  final double altitude;

  TPV(this.type, this.mode, this.latitude, this.longitude, this.altitude);

  void printCoordinates() {
    final latValues = decimalMinutesToDMS(latitude);
    final lonValues = decimalMinutesToDMS(longitude);

    print("Latitude: ${latValues[0]} degrees, ${latValues[1]} minutes, ${latValues[2]} seconds"); 
    print("Longitude: ${lonValues[0]} degrees, ${lonValues[1]} minutes, ${lonValues[2]} seconds");
  }

  void printAltitude() {
    print('Altitude: $altitude meters');
  }
  List<double> decimalMinutesToDMS(double decimalMinutes) {
    final degrees = decimalMinutes ~/ 100;
    final decimalPart = decimalMinutes % 100;
    final minutes = decimalPart.toInt();
    final seconds = (decimalPart - minutes) * 60;
    
    return [degrees.toDouble(), minutes.toDouble(), seconds];
  }
}

TPV? parseNMEA(String nmeaSentence) {
  var parts = nmeaSentence.split(',');
  var lat = (double.tryParse(parts[2]) ?? 0.0);
  final tag = parts.first;
  if(tag.endsWith('GGA')) {
    return TPV(
      'TPV',
      int.tryParse(parts[6]) ?? 0, //mode
      (double.tryParse(parts[2]) ?? 0.0), // latitude
      (double.tryParse(parts[4]) ?? 0.0), // longitude
      double.tryParse(parts[9]) ?? 0.0, // altitude
    );

  } else if(tag.endsWith('RMC')){
    var parts = nmeaSentence.split(',');
    var lat = (double.tryParse(parts[2]) ?? 0.0) / 100;
    return TPV(
      'TPV',
      int.tryParse(parts[12]) ?? 0, // mode
      (double.tryParse(parts[3]) ?? 0.0), // latitude
      (double.tryParse(parts[5]) ?? 0.0), // longitude
      double.tryParse(parts[9]) ?? 0.0, // altitude
    );
  }
  return null;
}

void main() async {
  var serialPort = '/dev/cu.usbmodem14201';

  //var tpv = parseNMEA(input);
  //if (tpv != null) {
  //  tpv.printCoordinates();
  //  tpv.printAltitude();
  //}

  var process = await Process.start('cat', [serialPort]);
  process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((line) {
    var tpv = parseNMEA(line);
    if (tpv != null) {
      tpv.printCoordinates();
      tpv.printAltitude();
    }
  });
}
